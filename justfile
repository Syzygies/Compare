set shell := ["/opt/homebrew/bin/bash", "-c"]

# List all available commands
default:
    @just --list --unsorted

# Create a new session log file with timestamp
log:
    @ path="log/$(date +%m-%d-%H%M).md"; \
    header="# Session Log: $(date +'%A %-d %B %Y') $(date +'%-l:%M %p' | tr '[:upper:]' '[:lower:]')"; \
    echo "$header" > "$path"; \
    echo "$path"

# Create today's working directory
today:
    @ mv today/[0-9][0-9]-[0-9][0-9] today/past/ 2>/dev/null || true; \
    day="today/$(date +%m-%d)" && mkdir -p "$day" && open "$day" && echo "$day"

# ---- vcs ---------------------------------------------------------

# Save all changes to hg
save *message:
    hg commit -A -m "{{ message }}"
    @hg status

# Undo last save, keeping changes
unsave:
    hg strip tip --keep

# Publish to git
publish *message:
    git add -A
    git commit -m "{{ message }}"

# Show hg status
status:
    @echo
    @hg status

# ---- search ------------------------------------------------------

# Find all files with name containing pattern
find pat dir=".":
    @find {{ dir }} -name "*{{ pat }}*" -type f | sort

# Search for pattern using ripgrep
grep pat dir=".":
    @rg "{{ pat }}" {{ dir }}

# ---- run ---------------------------------------------------------

# Run language implementation
run lang *args="":
    @cd source/{{ lang }} && ./run {{ args }}

# Run benchmarks e.g. just do scala 4x 10
do *args="":
    @bin/exercise {{ args }}

# Format source code (F#, ocaml, haskell, scala)
format lang="scala":
    @if [ "{{ lang }}" = "scala" ]; then scalafmt source/scala/src/*.scala; \
    else bin/format {{ lang }}; fi

# Switch all implementations to Tarjan algorithm
Tarjan:
    bin/switch-algorithm Tarjan

# Switch all implementations to Loops algorithm
Loops:
    bin/switch-algorithm Loops

# Choose F# versions
vers n:
    rm -f source/F#/src/perms.fs
    ln -s vers/v{{ n }}-perms.fs source/F#/src/perms.fs
    tree --filesfirst -CF --noreport source/F#/src

# Show timings
show algorithm *args="":
    bin/show-timings {{ algorithm }} {{ args }}

# Save reports for both algorithms at n=10
report:
    bin/show-timings -s Tarjan 10
    bin/show-timings -s Loops 10
