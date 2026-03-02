const API_BASE = '/api/v1';
const HISTORY_KEY = 'sql-practice-session-history';

let editor;
let currentDiagnostics = [];

const state = {
  engine: 'postgres',
  dataset: '',
};

const nodes = {
  engineSelect: document.getElementById('engine-select'),
  datasetSelect: document.getElementById('dataset-select'),
  rowLimit: document.getElementById('row-limit'),
  runButton: document.getElementById('run-query'),
  lintButton: document.getElementById('lint-query'),
  clearHistoryButton: document.getElementById('clear-history'),
  diagnostics: document.getElementById('diagnostics'),
  metrics: document.getElementById('metrics'),
  resultMeta: document.getElementById('result-meta'),
  resultsTable: document.getElementById('results-table'),
  explainOutput: document.getElementById('explain-output'),
  historyList: document.getElementById('history-list'),
};

function escapeHtml(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

async function fetchJson(url, options = {}) {
  const response = await fetch(url, {
    headers: {
      'Content-Type': 'application/json',
    },
    ...options,
  });

  if (!response.ok) {
    const errorBody = await response.text();
    throw new Error(errorBody || `Request failed with status ${response.status}`);
  }

  return response.json();
}

function loadHistory() {
  try {
    const raw = sessionStorage.getItem(HISTORY_KEY);
    return raw ? JSON.parse(raw) : [];
  } catch {
    return [];
  }
}

function persistHistory(entries) {
  sessionStorage.setItem(HISTORY_KEY, JSON.stringify(entries.slice(0, 40)));
}

function addHistoryEntry(entry) {
  const history = loadHistory();
  history.unshift(entry);
  persistHistory(history);
  renderHistory();
}

function renderHistory() {
  const history = loadHistory();

  if (!history.length) {
    nodes.historyList.innerHTML = '<div class="history-item">No queries in this session.</div>';
    return;
  }

  nodes.historyList.innerHTML = history
    .map((item, index) => {
      const preview = escapeHtml(item.sql.split('\n').join(' ').slice(0, 140));
      return `
        <div class="history-item" data-history-index="${index}">
          <div class="history-item__meta">${escapeHtml(item.timestamp)} | ${escapeHtml(item.dataset)} | ${escapeHtml(item.status)}</div>
          <div>${preview}</div>
        </div>
      `;
    })
    .join('');

  nodes.historyList.querySelectorAll('[data-history-index]').forEach((item) => {
    item.addEventListener('click', () => {
      const index = Number(item.dataset.historyIndex);
      const selected = loadHistory()[index];
      if (selected) {
        editor.setValue(selected.sql);
      }
    });
  });
}

function renderDiagnostics(diagnostics) {
  currentDiagnostics = diagnostics;

  if (!diagnostics.length) {
    nodes.diagnostics.innerHTML = '<div class="msg">No errors or warnings.</div>';
    return;
  }

  nodes.diagnostics.innerHTML = diagnostics
    .map((item) => {
      const klass = item.severity === 'error' ? 'msg--error' : item.severity === 'warning' ? 'msg--warning' : '';
      const code = item.code ? `[${escapeHtml(item.code)}] ` : '';
      return `<div class="msg ${klass}">${code}Line ${item.line}, Col ${item.start_col}: ${escapeHtml(item.message)}</div>`;
    })
    .join('');
}

function renderMetrics(metrics) {
  const entries = [
    ['Parse', `${metrics.parse_ms?.toFixed(3) ?? '0.000'} ms`],
    ['Lint', `${metrics.lint_ms?.toFixed(3) ?? '0.000'} ms`],
    ['Execute', `${metrics.execute_ms?.toFixed(3) ?? '0.000'} ms`],
    ['Total', `${metrics.total_ms?.toFixed(3) ?? '0.000'} ms`],
    ['Rows', String(metrics.row_count ?? 0)],
  ];

  if (metrics.explain?.planning_time_ms != null) {
    entries.push(['Plan Time', `${Number(metrics.explain.planning_time_ms).toFixed(3)} ms`]);
  }

  if (metrics.explain?.execution_time_ms != null) {
    entries.push(['Plan Execute', `${Number(metrics.explain.execution_time_ms).toFixed(3)} ms`]);
  }

  nodes.metrics.innerHTML = entries
    .map(
      ([label, value]) =>
        `<div class="metric"><div class="metric__label">${escapeHtml(label)}</div><div class="metric__value">${escapeHtml(value)}</div></div>`
    )
    .join('');
}

function renderResultTable(columns, rows) {
  if (!columns.length) {
    nodes.resultsTable.innerHTML = '';
    return;
  }

  const head = `<thead><tr>${columns.map((col) => `<th>${escapeHtml(col)}</th>`).join('')}</tr></thead>`;

  const body = `<tbody>${rows
    .map(
      (row) => `<tr>${columns
        .map((col) => `<td>${escapeHtml(row[col] === null || row[col] === undefined ? 'NULL' : row[col])}</td>`)
        .join('')}</tr>`
    )
    .join('')}</tbody>`;

  nodes.resultsTable.innerHTML = `${head}${body}`;
}

function renderExplain(explain) {
  if (!explain) {
    nodes.explainOutput.textContent = '';
    return;
  }

  nodes.explainOutput.textContent = JSON.stringify(explain.plan, null, 2);
}

function applyMonacoMarkers(diagnostics) {
  if (!window.monaco || !editor) {
    return;
  }

  const model = editor.getModel();
  if (!model) {
    return;
  }

  const markers = diagnostics.map((item) => ({
    severity:
      item.severity === 'error'
        ? monaco.MarkerSeverity.Error
        : item.severity === 'warning'
          ? monaco.MarkerSeverity.Warning
          : monaco.MarkerSeverity.Info,
    message: item.message,
    startLineNumber: item.line || 1,
    startColumn: item.start_col || 1,
    endLineNumber: item.line || 1,
    endColumn: item.end_col || (item.start_col || 1) + 1,
    code: item.code || undefined,
  }));

  monaco.editor.setModelMarkers(model, 'sql-practice', markers);
}

async function lintOnly() {
  const payload = {
    sql: editor.getValue(),
    engine: state.engine,
  };

  const result = await fetchJson(`${API_BASE}/lint`, {
    method: 'POST',
    body: JSON.stringify(payload),
  });

  renderDiagnostics(result.diagnostics || []);
  applyMonacoMarkers(result.diagnostics || []);

  renderMetrics({
    parse_ms: result.lint_ms,
    lint_ms: result.lint_ms,
    execute_ms: 0,
    total_ms: result.lint_ms,
    row_count: 0,
  });
}

function nowIsoLocal() {
  return new Date().toLocaleString();
}

async function executeQuery() {
  const sql = editor.getValue();
  const payload = {
    sql,
    engine: state.engine,
    dataset: state.dataset,
    row_limit: Number(nodes.rowLimit.value) || 200,
    include_explain: true,
  };

  try {
    const result = await fetchJson(`${API_BASE}/query`, {
      method: 'POST',
      body: JSON.stringify(payload),
    });

    renderDiagnostics(result.diagnostics || []);
    applyMonacoMarkers(result.diagnostics || []);
    renderMetrics(result);

    if (result.ok) {
      nodes.resultMeta.textContent = `${result.command || 'QUERY'} completed on ${result.dataset}. Rows shown: ${result.row_count}${result.truncated ? ' (truncated)' : ''}`;
      renderResultTable(result.columns || [], result.rows || []);
      renderExplain(result.explain);
    } else {
      nodes.resultMeta.textContent = result.error || 'Query failed.';
      renderResultTable([], []);
      renderExplain(null);
    }

    addHistoryEntry({
      timestamp: nowIsoLocal(),
      dataset: result.dataset,
      status: result.ok ? 'ok' : 'error',
      execute_ms: result.execute_ms,
      sql,
    });
  } catch (error) {
    nodes.resultMeta.textContent = `Request failed: ${error.message}`;
  }
}

function seedStarterQuery() {
  const starter = `SELECT e.employee_id,
       e.first_name,
       e.last_name,
       d.department_name,
       o.order_count
FROM employees e
JOIN departments d ON d.department_id = e.department_id
LEFT JOIN (
    SELECT employee_id, COUNT(*) AS order_count
    FROM sales_orders
    GROUP BY employee_id
) o ON o.employee_id = e.employee_id
ORDER BY o.order_count DESC NULLS LAST
LIMIT 25;`;
  editor.setValue(starter);
}

async function loadEngines() {
  const engines = await fetchJson(`${API_BASE}/engines`);

  nodes.engineSelect.innerHTML = engines
    .map((engine) => `<option value="${escapeHtml(engine.name)}" ${engine.enabled ? '' : 'disabled'}>${escapeHtml(engine.label)}</option>`)
    .join('');

  state.engine = nodes.engineSelect.value;
}

async function loadDatasets() {
  const datasets = await fetchJson(`${API_BASE}/datasets?engine=${encodeURIComponent(state.engine)}`);

  nodes.datasetSelect.innerHTML = datasets
    .map((dataset) => `<option value="${escapeHtml(dataset.name)}">${escapeHtml(dataset.name)}</option>`)
    .join('');

  state.dataset = nodes.datasetSelect.value;
}

function bindEvents() {
  nodes.engineSelect.addEventListener('change', async () => {
    state.engine = nodes.engineSelect.value;
    await loadDatasets();
  });

  nodes.datasetSelect.addEventListener('change', () => {
    state.dataset = nodes.datasetSelect.value;
  });

  nodes.lintButton.addEventListener('click', lintOnly);
  nodes.runButton.addEventListener('click', executeQuery);
  nodes.clearHistoryButton.addEventListener('click', () => {
    sessionStorage.removeItem(HISTORY_KEY);
    renderHistory();
  });
}

function initMonaco() {
  return new Promise((resolve) => {
    window.require.config({
      paths: {
        vs: 'https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.52.2/min/vs',
      },
    });

    window.require(['vs/editor/editor.main'], () => {
      editor = monaco.editor.create(document.getElementById('editor'), {
        value: '',
        language: 'sql',
        automaticLayout: true,
        minimap: { enabled: false },
        fontFamily: 'Consolas, Menlo, monospace',
        fontSize: 14,
        lineNumbersMinChars: 3,
        tabSize: 2,
        theme: 'vs',
      });

      editor.addCommand(monaco.KeyMod.CtrlCmd | monaco.KeyCode.Enter, () => {
        executeQuery();
      });

      resolve();
    });
  });
}

async function init() {
  await initMonaco();
  await loadEngines();
  await loadDatasets();

  bindEvents();
  renderHistory();
  renderDiagnostics([]);
  renderMetrics({ parse_ms: 0, lint_ms: 0, execute_ms: 0, total_ms: 0, row_count: 0 });
  seedStarterQuery();
}

init().catch((error) => {
  document.body.innerHTML = `<pre>Failed to initialize app: ${escapeHtml(error.message)}</pre>`;
});
