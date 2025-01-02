# How to Release a New Version

## Release Official Versions

To release a new version, follow these steps after creating a PR with your changes:

### 1. Update the Changeset File

In your branch, run the following command to create a new changeset file:

```bash
npm run cs
```

You will be prompted to specify the type of changes you are making. Choose from the following options:

-   `patch`: bug fixes, documentation updates, etc.
-   `minor`: new features, non-breaking changes, etc.
-   `major`: breaking changes, etc.

Next, you will be prompted to enter a summary of the changes you made. This will be used to generate the release notes in the `CHANGELOG.md` file.

### 2. Commit the Changeset File

```bash
git add .
git commit -m "chore: update changeset"
git push
```

### 3. Trigger the release workflow:

#### Overview:

These GitHub actions workflows manage releases based on `changesets` we defined earlier, ensuring that every new release includes tracked changes and proper version updates. The process starts when the `pre-release` workflow is triggered. If the PR includes changesets, the workflow generates a new "PR version", which needs to be reviewed and eventually merged in order to trigger the `release` workflow that publishes the new packages.

#### Pre-Release Workflow:

- This `pre-release` workflow kicks in after it gets triggered manually by one of the authorized team members, it does the following:

  - Generates a new version based on the `changesets`.
  - Updates the package version.
  - Updates the `CHANGELOG.md` file with the changes made in the release.
  - Creates a new release PR with the updated version changes.

#### Release Workflow:

- Once the `release` PR is reviewed, approved and merged, if the PR title contains certain criteria, the `release` workflow is triggered in order to publish the new release:

  - Installs any necessary dependencies needed for the package publishing (e.g. `node.js`).
  - Publishes the release.
  - Pushes release tags to the repository and all the related assets.

#### Important Considerations:

If no changesets are provided, the release will lack a changelog, and versioning won’t be updated.

Best practice requires every release to include changes tracked by changesets to maintain proper version history and changelogs.

## Release Snapshot Versions

If you need to release a snapshot version for development or testing purposes, you can do so by triggering the snapshot release workflow [here](https://github.com/axelarnetwork/interchain-token-service/actions/workflows/release-snapshot.yaml)
