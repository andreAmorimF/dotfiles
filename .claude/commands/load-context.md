For each directory listed in $ARGUMENTS, load project context by reading (if present):
1. CLAUDE.md
2. README.md or README.adoc
3. The root build file (build.sbt, deps.edn, pom.xml, package.json, etc.)

After reading all projects, output a structured summary:
- **Project name & purpose** (1-2 sentences)
- **Tech stack** (languages, key frameworks/libraries)
- **Key interfaces or APIs** exposed or consumed
- **Known cross-project dependencies** (does it depend on or is depended on by the others?)

End with a "Dependency Map" section showing how the listed projects relate to each other.

Once done, confirm and wait for the feature description.
