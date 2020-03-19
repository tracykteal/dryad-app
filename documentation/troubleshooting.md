Troubleshooting
==================

Some common problems and how to deal with them.

Also see the notes on
[handling failed submissions](https://confluence.ucop.edu/display/Stash/Dryad+Operations#DryadOperations-FixingaFailedSubmission).


Merrit async download check
===========================

This error typically means that the account being used by the Dryad UI
to access Merritt does not have permisisons for the object being
requested. This is often because either the Dryad UI or the object in
Merritt is using a UC-based account, while the other is using a non-UC account.


Dataset is not showing up in searches
===================================

If a dataset does not appear in search results, it probably needs to be
reindexed in SOLR. In a rails console, obtain a copy of the object and
force it to index:

```
r=StashEngine::Resource.find(<resource_id>)
r.submit_to_solr
```

Forcing a dataset to submit
============================

Sometimes a dataset becomes "stuck in progress". This is often due to
confusion on the part of a user, but there are times when the user
loses access to editing a particular version of a dataset. Find the
most recent resource object associated with that dataset, and force it
to submit:

```
StashEngine.repository.submit(resource_id: <resource_id>)
```