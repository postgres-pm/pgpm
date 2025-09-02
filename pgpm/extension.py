import os
import clips

class ExtensionModule:

    def __init__(self, env: clips.Environment):
        self.env = env
        self.env.load(os.path.join(os.path.dirname(__file__), "extension.clp"))

    def extension_versions(self, name: str):
        tpl = self.env.find_template('extension-versions')
        a = tpl.assert_fact(name=name)
        self.env.run()
        result = list(a['versions'])
        a.retract()
        return result

    def source_path_for(self, extension: str, version: str) -> str:
        tpl = self.env.find_template('extension-versions')
        request = tpl.assert_fact(name=extension)
        self.env.run()
        version_index = list(request['versions']).index(version)
        version_ref = request['version-refs'][version_index]
        request.retract()
        tpl = self.env.find_template('source-path')
        source_path = tpl.assert_fact(ref=version_ref)
        self.env.run()
        return source_path['value']
