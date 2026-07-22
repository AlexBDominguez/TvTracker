from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel


class CamelModel(BaseModel):
    """Base for schemas consumed by the Flutter frontend, which expects camelCase JSON."""

    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)
