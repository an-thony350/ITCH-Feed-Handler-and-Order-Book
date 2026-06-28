

To install autoformatter
```bash
python3 -m venv .venv
source .venv/bin/activate
pre-commit install
deactivate
```

To run:
```bash
./scripts/format.sh
```
or
```bash
pre-commit run --all-files
```

If autoformatter finds formatting issues, it will fix, but you have to stage the commit again.
