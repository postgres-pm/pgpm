import os
import pathlib
import tempfile
import hashlib
import typing

import clips
import pygit2
import rich.progress
from pygments.lexers.sql import PostgresBase

MODULE = [

]


class git_cb(pygit2.RemoteCallbacks):
    def __init__(self, pb, task_id):
        super().__init__()
        self.pb = pb
        self.task_id = task_id

    def transfer_progress(self, stats: pygit2.remotes.TransferProgress) -> None:
        self.pb.update(task_id=self.task_id, total=stats.total_objects, completed=stats.received_objects, refresh=True)


class GitModule:

    def __init__(self, env: clips.Environment):
        self.env = env

        self.env.define_function(self.git_fetch_heads, "git-fetch-heads")
        self.env.define_function(self.git_clone_repository, "git-clone-repository")

        self.env.load(os.path.join(os.path.dirname(__file__), "git.clp"))
        for module in MODULE:
            self.env.build(module)

    def git_fetch_heads(self, ref: clips.TemplateFact, url: str):
        temp_dir = tempfile.mkdtemp()
        repo = pygit2.init_repository(temp_dir, bare=True)
        remote = repo.remotes.create("origin", url)
        tpl = self.env.find_template("git-repository-head")
        progress = rich.progress.Progress(
            rich.progress.SpinnerColumn(),
            rich.progress.TextColumn("[progress.description]{task.description}"),
            rich.progress.TextColumn("Processed: {task.completed}"),
            rich.progress.TimeElapsedColumn(),
            transient=True)
        with progress:
            id = progress.add_task(f"Listing heads at {url}")
            cb = git_cb(progress, id)
            for i, head in enumerate(remote.list_heads(callbacks=cb)):
                tpl.assert_fact(ref=ref, value=head.name)
                progress.update(task_id=id, completed=i, refresh=True)

    def git_clone_repository(self, src: clips.TemplateFact, url: str, reference: str):
        # TODO: optimize by cloning the main repo and then cloning it locally and getting
        # the specific revision. Will help with getting multiple versions
        path = os.path.join('repos', hashlib.sha1(f"{url}#{reference}".encode('utf-8')).hexdigest())

        progress = rich.progress.Progress(transient=True)
        if os.path.exists(path):
            repo = pygit2.Repository(path)
            # id = progress.add_task(f"Updating {url}")
            # cb = git_cb(progress, id)
            # repo.remotes["origin"].fetch(callbacks=cb)
        else:
            with progress:
                id = progress.add_task(f"Cloning {url}")
                cb = git_cb(progress, id)
                repo = pygit2.clone_repository(url=url, path=path, callbacks=cb)
        tag = repo.revparse_single(reference)
        repo.checkout_tree(tag)
        repo.set_head(tag.id)
        src.modify_slots(value=str(pathlib.Path(path).absolute()))
