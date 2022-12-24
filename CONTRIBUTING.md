# Contribution guidelines

First of all, thanks for thinking of contributing to this project.

Before sending a Pull Request, please make sure that you're assigned the task on a GitHub issue.

- If a relevant issue already exists, discuss on the issue and get it assigned to yourself on GitHub.
- If no relevant issue exists, open a new issue and get it assigned to yourself on GitHub.

In order to ensure that you're hardwork isn't wasted, please proceed with a PR only after you're assigned an issue.

## Installation

Before starting to work on the issue, make sure that you're able to build the app successfully from source. For any help with building refer to the [Installation](README.md#Installation) part of the README.

## Pull request structure

In order to pass the checks in the CI, you have to make sure of the following:

1. `flutter analyze` check is passing
2. You have a file in `pending/changes/` that indicates the changes with the correct structure*
3. You have a file in `pending/versions/` that indicates the version with the correct structure**

*`pending/changes` files structure:
- The file should be named as `<pr_id>.md` where `<pr_id>` is the pull request unique id (can be found in the PR url).
- The first line in the file should be in the format: `- <pr_title> (!<pr_id>)` where `<pr_title>` is the title of the PR. The title should be concise, not too short nor too long, and clearly state the main changes in the PR.
- The second and last line should be an empty line (no empty spaces or anything else).
- [Example](https://github.com/goar5670/Tinder-with-Chuck-Norris/pull/11/files#diff-c5599a0ea72ecd10e4c7871563f10bab71614073566fafc20ed11cf0bf4ebfc1)

**`pending/versions` files structure:
- The file should be named as `<pr_id>.asc` where `<pr_id>` is the pull request unique id (can be found in the PR url).
- The first and only line should contain one of "patch", "minor", or "major" respectively with no leading or trailing spaces
- [Example](https://github.com/goar5670/Tinder-with-Chuck-Norris/pull/11/files#diff-f484a731d869bc4556afbd3420976bf793669886259a6ffcb88466b6c8356f59)

