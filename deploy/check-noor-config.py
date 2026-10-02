"""Check resolved Compose configuration without logging secret values."""
import json
import sys


def configured(value):
    return isinstance(value, str) and value.strip().lower() not in {
        "", "null", "(null)", "false", "(false)", "empty", "(empty)",
    }


def main():
    try:
        configuration = json.load(sys.stdin)
        environment = configuration["services"]["api"]["environment"]
        if not isinstance(environment, dict):
            raise ValueError()
    except (ValueError, KeyError, TypeError):
        print("ERROR: unable to read resolved API configuration.", file=sys.stderr)
        return 1

    if not configured(environment.get("GROQ_API_KEY")):
        print("ERROR: GROQ_API_KEY is missing or empty in the resolved API environment. Noor requires a server-side key.", file=sys.stderr)
        return 1
    if not configured(environment.get("GROQ_MODEL")):
        print("WARNING: GROQ_MODEL is not set; Laravel will use its default model.")
    print("==> Noor API environment is configured.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
