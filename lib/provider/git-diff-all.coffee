_ = require 'underscore-plus'
ProviderBase = require './provider-base'
path = require 'path'
fs = require 'fs-plus'
{itemForGitDiff} = require '../utils'

# Borrowed and modified from fuzzy-finder's git-diff-view.coffee
eachModifiedFilePaths = (fn) ->
  for repo in atom.project.getRepositories() when repo?
    workingDirectory = repo.getWorkingDirectory()
    for filePath of repo.statuses
      filePath = path.join(workingDirectory, filePath)
      if fs.isFileSync(filePath)
        fn(repo, filePath)

getItemsForFilePath = (repo, filePath) ->
  atom.workspace.open(filePath, activateItem: false).then (editor) ->
    # When file was completely new file, getLineDiffs return null, so need guard.
    diffs = repo.getLineDiffs(filePath, editor.getText()) ? []
    diffs.map (diff) ->
      itemForGitDiff(diff, {editor, filePath})

module.exports =
class GitDiffAll extends ProviderBase
  refreshOnDidSave: true
  showProjectHeader: true
  showFileHeader: true

  getItems: ->
    promises = []
    eachModifiedFilePaths (repo, filePath) =>
      promise = getItemsForFilePath(repo, filePath).then (items) =>
        @updateItems(_.compact(items))
      promises.push(promise)

    Promise.all(promises).then =>
      @finishUpdateItems()
