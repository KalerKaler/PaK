#!/usr/bin/env fish
# dedup.fish: remove byte-identical images, keep one per group
# usage:  fish dedup.fish /path/to/images            (dry run)
#         fish dedup.fish /path/to/images --delete   (actually delete)

set dir $argv[1]
if test -z "$dir"; or not test -d "$dir"
    echo "usage: dedup.fish DIR [--delete]"
    exit 1
end

set hashes (mktemp)

echo "hashing files..."
find $dir -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) -print0 \
    | sort -z \
    | xargs -0 sha256sum > $hashes

set total (wc -l < $hashes | string trim)

# lines look like "<64 hex chars>  <path>", path starts at column 67.
# The first path per hash (in sorted order) is kept; the rest are duplicates.
awk 'seen[$1]++ { print substr($0, 67) }' $hashes > dupes.txt
set ndupes (wc -l < dupes.txt | string trim)

echo "$total files, $ndupes duplicates"

if contains -- --delete $argv
    awk -v ORS='\0' 'seen[$1]++ { print substr($0, 67) }' $hashes | xargs -0 -r rm --
    echo "deleted $ndupes files (list saved in dupes.txt)"
else
    echo "dry run: nothing deleted. Review dupes.txt, then rerun with --delete"
end

rm -f $hashes
