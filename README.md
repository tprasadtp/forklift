# Sync Fork

[![build](https://github.com/tprasadtp/forklift/workflows/build/badge.svg?branch=master)](https://github.com/tprasadtp/forklift/actions?query=workflow%3Abuild)
[![lables](https://github.com/tprasadtp/forklift/workflows/lables/badge.svg)](https://github.com/tprasadtp/forklift/actions?query=workflow%3Alabels)
![Analytics](https://ga-beacon.prasadt.com/UA-101760811-3/github/forklift)

Keeps Minimally modified forks in sync.

## Action

This is best used as a cron triggered GitHub action. Example usage is shown below.

```yaml
name: forklift
on:
  schedule:
    # Every Friday
    - cron:  "0 18 * * FRI"
jobs:
  forklift:
    runs-on: ubuntu-latest
    steps:
    - name: sync-fork
    - uses: actions/checkout@v2
    - uses: tprasadtp/forklift@0.2.0
      with:
        upstream_url: "URL for upstream repo. This must be HTTP" # Required! Upstream https clone URL
        upstream_branch: "master"   # Upstream Branch to use (Defaults to master)
        branch: "master"   # Local Branch
        method: "rebase"   # Method to use. Can be `merge`, `merge-ff-only` or `rebase`.
        args: "--no-push"  # Additional Arguments
```

## Help

<pre><font color="#C3D82C">➜</font> ./forklift.sh <font color="#00ACC1">-h</font>
Usage: <font color="#00D787">forklift.sh </font><font color="#AFFFFF">  [options]</font>

- Keeps minimally modified forks in sync.
- Please do not use this for forks with extensive
  modifications.

<font color="#FF8700">-------------- Required Arguments ------------------------</font>
[-u --upstream-url]     Upstream URL to set (Required)

<font color="#D7FF87">-------------- Optional Arguments ------------------------</font>
[-m --method]           Method to use (Defaults is merge-ff)
[-b --branch]           Branch to merge/rebase
[-x --upstream-branch]  Upstream Branch to merge/rebase
                        (Defaults is master)

<font color="#949494">---------------- Other Arguments -------------------------</font>
<font color="#949494">[--no-push]             Skip Git Push</font>
<font color="#949494">[-s skip-git-config]    Skip configuring git committer</font>
<font color="#949494">[-v --verbose]          Enable verbose logging</font>
<font color="#949494">[-h --help]             Display this help message</font>

<font color="#FF87D7">-------------- About &amp; Version Info -----------------------</font>
- Action Version - 0.2.0
- This is best used as Github Action.
- Defaults are only populated when running as GitHub action.

See <font color="#AFFFFF">https://git.io/JtV8L</font> for more info.

</pre>
