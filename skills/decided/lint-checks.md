# ADR Lint Checks

Run for each file touched during a workflow invocation. Fix any failure before reporting completion.

## Decision files (`NNNN-*.md`)

```bash
FILE="<ADR_DIR>/NNNN-slug.md"   # substitute actual path

# Check 1: required fields present
for field in type id title status date; do
  rg -q "^${field}:" "$FILE" || echo "FAIL check 1: missing field '$field' in $FILE"
done

# Check 2: valid status value
status=$(rg -m1 "^status:" "$FILE" | sed 's/^status: *//')
echo "$status" | rg -q "^(proposed|rejected|active|superseded|retired)$" \
  || echo "FAIL check 2: invalid status '$status' in $FILE"

# Check 3: if superseded, superseded_by must be non-empty wikilink
if [ "$status" = "superseded" ]; then
  sb=$(rg -m1 "^superseded_by:" "$FILE" | sed 's/^superseded_by: *//' | tr -d '"')
  [ -z "$sb" ] \
    && echo "FAIL check 3: status is superseded but superseded_by is empty in $FILE"

  # Check 4: wikilink target resolves
  target=$(echo "$sb" | sed 's/\[\[//;s/\]\]//')
  [ -f "<ADR_DIR>/${target}.md" ] \
    || echo "FAIL check 4: superseded_by target not found: <ADR_DIR>/${target}.md"
fi

# Check 5: id is unique across all decision files
id=$(rg -m1 "^id:" "$FILE" | sed 's/^id: *//' | tr -d '"')
count=$(rg -l "^id: \"${id}\"" <ADR_DIR>/[0-9]*.md | wc -l | tr -d ' ')
[ "$count" -gt 1 ] \
  && echo "FAIL check 5: id '$id' appears in $count files"
```

## Index file (`index.md`)

```bash
BASENAME=$(basename "$FILE")

# Check 6: touched decision file appears in index
rg -q "$BASENAME" <ADR_DIR>/index.md \
  || echo "FAIL check 6: $BASENAME not found in <ADR_DIR>/index.md"

# Check 7: index markdown link for this file points to existing file
rg "\($BASENAME\)" <ADR_DIR>/index.md | rg -q . \
  || echo "FAIL check 7: no markdown link for $BASENAME in index"
```
