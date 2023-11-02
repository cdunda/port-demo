import json
import sys


def try_parse_json_recursive(obj):
    if isinstance(obj, str):
        try:
            obj = json.loads(obj)
        except json.JSONDecodeError:
            return obj

    if isinstance(obj, dict):
        for key, value in obj.items():
            obj[key] = try_parse_json_recursive(value)
    elif isinstance(obj, list):
        for i, value in enumerate(obj):
            obj[i] = try_parse_json_recursive(value)

    return obj


if __name__ == "__main__":
    data = json.load(sys.stdin)
    data = try_parse_json_recursive(data)
    print(json.dumps(data, indent=4))
