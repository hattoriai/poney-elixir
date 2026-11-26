# Conformance

The [Poney specification](https://github.com/hattoriai/poney/blob/main/spec/SPEC.md)
defines a conforming reader (§2): it accepts every valid document, refuses
every invalid one, reports problems with their paths, and keeps data it does
not understand when it writes a document back. This library is one.

## The copy of the standard

Three parts of the specification live in this repository, copied from a
tagged release of Poney:

| From Poney | Here | Used for |
|---|---|---|
| `spec/poney.schema.json` | `priv/spec/poney.schema.json` | The shape check, at run time |
| `spec/conformance/` | `test/conformance/` | The conformance tests |
| `spec/examples/*.poney` | `test/fixtures/examples/` | Tests on real documents |

`priv/spec/source.json` says which release they come from. To take a newer
one:

```sh
mix poney.spec v0.3.0
mix test
```

`mix poney.spec` downloads the files from GitHub, or reads them from a local
checkout with `--from ../poney`.

## How the library reads the schema

The library reads the published JSON Schema with its own small
interpreter, for the keywords that schema uses. It fails to compile when a
new schema uses a keyword it does not know, so the check never weakens
quietly. Reading the schema itself, it can:

- name the member at fault inside a union (a view with a wrong field gets
  that field's error, not "matches none of ten forms");
- fill in the defaults in the same walk: the canonical form;
- need no dependency at run time.

The tests check it against a full JSON Schema validator (JSV): on hundreds of
random changes to a real document, both must agree on whether the shape fits.

## The other rules

The rules that JSON Schema cannot say (§9.2: unique ids, references, behaviors,
walkthroughs; §8.4: extensions) are written after Poney's
reference reader in TypeScript. The conformance suite lists the paths each
invalid document must report.
