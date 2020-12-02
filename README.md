# Vault KV Recursive List/Dump/Copy/Delete

## Requirements

1. The `vault` binary somewhere in `$PATH`.
2. Vault token and config pre-set in the environment.
3. Bash, GNU Utils, JQ.

## Usage

### List

Recursively list all keys under specified path.

```
# ./vault_recursive.sh list secret/foo/

secret/foo/bar
secret/foo/baz/config
```

### Dump

Recursively dump all keys under specified path.

```
# ./vault_recursive.sh dump secret/foo/

= secret/foo/bar
  { ... }
= secret/foo/baz/config
  { ... }
```

### Copy

Recursively copy keys from one path to another.

* Set `DO_FORCE=yes` to skip confirmation prompt.

```
# ./vault_recursive.sh copy secret/foo/ secret/bar/

You are about to do the following:
  secret/foo/bar         >>  secret/bar/bar
  secret/foo/baz/config  >>  secret/bar/baz/config
Do you wish to continue? Yes/[No]:
```

### Delete

Recursively delete keys under specified path.

* Set `DO_FORCE=yes` to skip confirmation prompt.
* Set `DO_PURGE=yes` to purge metadata as well.
	* **IMPORTANT:** Remember that this removes all version history.

```
# ./vault_recursive.sh delete secret/foo/ secret/bar/

You are about to do the following:
  vault kv delete secret/foo/bar
  vault kv delete secret/foo/baz/config
Do you wish to continue? Yes/[No]:
```
