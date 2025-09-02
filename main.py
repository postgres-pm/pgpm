# nuitka-project: --standalone
# nuitka-project: --output-filename=pgpm.bin
# nuitka-project: --include-package=cffi
# nuitka-project: --nofollow-import-to=cffi.setuptools_ext
# nuitka-project: --nofollow-import-to=cffi._shimmed_dist_utils
# nuitka-project: --include-package-data=pgpm:*.clp
# nuitka-project: --assume-yes-for-downloads
import os

import rich
import clips

from ruamel.yaml import YAML

import pgpm.extension
import pgpm.core
import pgpm.git


def main():
    env = clips.Environment()
    pgpm.core.CoreModule(env)
    ext = pgpm.extension.ExtensionModule(env)
    pgpm.git.GitModule(env)

    def assert_rel(relation, fact, content):
        match content:
            case str():
                relation.assert_fact(ref=fact, value=content)
            case list():
                for item in content:
                    assert_rel(relation, fact, item)
            case dict():
                relation.assert_fact(ref=fact, **content)

    def load(file):
        documents = list(YAML().load_all(file))
        for document in documents:
            for key, values in document.items():
                for value in values:
                    try:
                        tpl = env.find_template(key)
                        slots = {slot.name: value[slot.name] for slot in tpl.slots}
                        fact = tpl.assert_fact(**slots)
                        remaining_slots = {k: v for k, v in value.items() if k not in slots.keys()}
                        for slot, content in remaining_slots.copy().items():
                            try:
                                relation = env.find_template(slot)
                                remaining_slots.pop(slot)
                                assert_rel(relation, fact, content)
                            except LookupError:
                                pass
                        if bool(remaining_slots):
                            rich.print("Remaining data", remaining_slots)
                    except LookupError:
                        rich.print(f"Could not find template {key}")

    with open("init.yaml", "r") as file:
        load(file)

    env.run()
    # rich.print(ext.extension_versions("pg_vector"))
    # ext.source_path_for("pg_vector", "0.8.0")
    rich.print(ext.extension_versions("pg_duckdb"))
    ext.source_path_for("pg_duckdb", "1.0.0")
    # rich.print(list(env.facts()))



if __name__ == "__main__":
    main()
