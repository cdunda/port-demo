import json
import sys


def try_parse_json(s):
    try:
        return json.loads(s)
    except json.JSONDecodeError:
        return s


if __name__ == "__main__":
    data = json.load(sys.stdin)
    for key, value in data.items():
        if isinstance(value, str):
            data[key] = try_parse_json(value)

    print(json.dumps(data, indent=4))
