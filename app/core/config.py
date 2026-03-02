from functools import cached_property

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file='.env', env_file_encoding='utf-8', extra='ignore')

    app_host: str = Field(default='127.0.0.1', alias='APP_HOST')
    app_port: int = Field(default=8000, alias='APP_PORT')

    postgres_host: str = Field(default='127.0.0.1', alias='POSTGRES_HOST')
    postgres_port: int = Field(default=5432, alias='POSTGRES_PORT')
    postgres_user: str = Field(default='postgres', alias='POSTGRES_USER')
    postgres_password: str = Field(default='postgres', alias='POSTGRES_PASSWORD')
    postgres_sslmode: str = Field(default='disable', alias='POSTGRES_SSLMODE')

    default_engine: str = Field(default='postgres', alias='DEFAULT_ENGINE')
    default_row_limit: int = Field(default=200, alias='DEFAULT_ROW_LIMIT')
    query_timeout_ms: int = Field(default=5000, alias='QUERY_TIMEOUT_MS')

    dataset_names: str = Field(
        default='sales_lab,hr_lab,finance_lab,healthcare_lab,logistics_lab,social_lab',
        alias='DATASET_NAMES',
    )

    @cached_property
    def datasets(self) -> list[str]:
        return [item.strip() for item in self.dataset_names.split(',') if item.strip()]

    def dsn_for_dataset(self, dataset_name: str) -> str:
        return (
            f"host={self.postgres_host} "
            f"port={self.postgres_port} "
            f"dbname={dataset_name} "
            f"user={self.postgres_user} "
            f"password={self.postgres_password} "
            f"sslmode={self.postgres_sslmode}"
        )


settings = Settings()
