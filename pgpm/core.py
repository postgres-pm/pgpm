import os.path

import clips
import mimetypes

mimetypes.add_type("text/x-perl", ".pl")
mimetypes.add_type("text/x-perl", ".pm")


class CoreModule:

    def __init__(self, env: clips.Environment):
        self.env = env

        self.env.define_function(self.assert_files, "assert-files")
        self.env.define_function(self.file_mimetype, "file-mimetype")
        self.env.load(os.path.join(os.path.dirname(__file__), "core.clp"))
        self.env.load(os.path.join(os.path.dirname(__file__), "c.clp"))

    def assert_files(self, ref: clips.TemplateFact, path: str):
        from pathlib import Path
        ignore_dirs = {'.git'}
        tpl = self.env.find_template('source-file')
        for file_path in Path(path).rglob("*"):
            if not os.path.isdir(file_path) and not any(part in ignore_dirs for part in file_path.parts):
                tpl.assert_fact(ref=ref, value=str(file_path.relative_to(path)))

    def file_mimetype(self, path: str):
        return mimetypes.guess_type(path)[0] or "application/octet-stream"
