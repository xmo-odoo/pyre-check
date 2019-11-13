import unittest
from unittest.mock import MagicMock

from .. import query_api


class QueryAPITest(unittest.TestCase):
    def test_defines(self) -> None:
        pyre_connection = MagicMock()
        pyre_connection.query_server.return_value = {
            "response": [
                {
                    "name": "a.foo",
                    "parameters": [{"name": "x", "annotation": "int"}],
                    "return_annotation": "int",
                }
            ]
        }
        self.assertEqual(
            query_api.defines(pyre_connection, ["a"]),
            [
                query_api.Define(
                    name="a.foo",
                    parameters=[query_api.DefineParameter(name="x", annotation="int")],
                    return_annotation="int",
                )
            ],
        )

    def test_get_class_hierarchy(self) -> None:
        pyre_connection = MagicMock()
        pyre_connection.query_server.return_value = {
            "response": [{"Foo": ["object"]}, {"object": []}]
        }
        self.assertEqual(
            query_api.get_class_hierarchy(pyre_connection),
            {"Foo": ["object"], "object": []},
        )
        pyre_connection.query_server.return_value = {
            "response": [
                {"Foo": ["object"]},
                {"object": []},
                # This should never happen in practice, but unfortunately can happen
                # due to the type of the JSON returned. The first entry wins.
                {"Foo": ["Bar"]},
                {"Bar": ["object"]},
            ]
        }
        self.assertEqual(
            query_api.get_class_hierarchy(pyre_connection),
            {"Foo": ["object"], "Bar": ["object"], "object": []},
        )
        pyre_connection.query_server.return_value = {"error": "Found an issue"}
        self.assertEqual(query_api.get_class_hierarchy(pyre_connection), None)
