---
name: cours-latex
description: Génère des notes de cours LaTeX complètes (informatique/maths) à partir d'un PDF de slides ou de polycopié — sommaire, couleurs, polices soignées, schémas TikZ, code minted, glossaire, démonstrations et intuitions pédagogiques. Compile via un conteneur Docker dédié (aucune dépendance LaTeX locale). Use when the user wants to turn a course PDF/slides into complete LaTeX study notes, or invokes /cours-latex.
---

# Cours LaTeX — notes de cours complètes à partir d'un PDF

> Toutes les commandes ci-dessous appellent des outils externes (docker,
> git, pdftotext) — identiques quel que soit l'environnement shell
> (Fish, Bash, PowerShell). Détecter le shell actif avant de choisir
> `compile.sh` vs `compile.ps1` (`rules/common/shell-fish.md`).

## Goal

Transformer un support de cours PDF (slides ou polycopié, informatique
ou maths) en notes de cours LaTeX complètes, fidèles et enrichies :
- **Exhaustivité** : chaque information du support source doit se
  retrouver dans le document final, reformulée clairement — rien n'est
  omis.
- **Enrichissement pédagogique** : intuitions non techniques, exemples
  pertinents, démonstrations ajoutées quand le résultat est standard et
  certain, sinon signalées explicitement comme absentes du support —
  **jamais d'information inventée**.
- **Rendu soigné** : sommaire cliquable, couleurs sobres, belles polices
  (Libertinus via LuaLaTeX), schémas TikZ pour les diagrammes techniques,
  blocs de code colorés (minted), glossaire des notions clés.
- **Contenu en français** : c'est une exception explicite et assumée à la
  règle globale "code en anglais" (`rules/common/coding-style.md`) —
  cette règle s'applique au *code/tooling* (Dockerfile, scripts, .sty,
  commentaires), pas au contenu académique produit, qui est le cours
  français de l'utilisateur.

Toute la chaîne de compilation est dockerisée — voir `docker/latex/README.md`
pour l'image et `examples/latex-*`/`examples/compile.*` pour les templates
copiés dans chaque nouveau repo de cours.

## Step 1 — Parser l'invocation

Arguments attendus : `<matière>` `<chemin-du-pdf>` `[semestre]`. Si un
argument manque, le demander en conversation plutôt que deviner.

Slugifier la matière (minuscules, accents retirés, espaces → tirets) pour
le nom de repo : ex. "Algorithmique avancée" → `algorithmique-avancee`.

## Step 2 — Localiser/créer le repo de cours

Chaque matière est son propre repo Git : `~/Code/cours-<matiere-slug>/`.

S'il n'existe pas encore :
1. `mkdir -p ~/Code/cours-<matiere-slug>/{chapitres,images}` et `git init`.
2. Copier depuis `examples/` (chemins relatifs à `claude-code-config/`) :
   - `latex-preamble.sty` → `cours-preamble.sty`
   - `latex-main.tex` → `main.tex`, en remplaçant les placeholders
     `<<MATIERE>>`, `<<SEMESTRE>>`, `<<AUTEUR>>`, `<<ETABLISSEMENT>>`
     (angle brackets, pas d'accolades — ne collisionnent jamais avec la
     syntaxe `{...}` de LaTeX). Demander `<<ETABLISSEMENT>>` si inconnu ;
     `<<AUTEUR>>` par défaut = nom de l'utilisateur.
   - `latex.gitignore` → `.gitignore`
   - `latex.latexmkrc` → `.latexmkrc`
   - `compile.sh` (avec permission d'exécution) et `compile.ps1`
3. Créer `glossaire.tex` vide.
4. Vérifier que l'image Docker existe : `docker image inspect cours-latex:latest`.
   Si absente, le signaler et proposer le build (`docker/latex/README.md`)
   plutôt que de builder silencieusement (image lourde, plusieurs minutes).

**Ne jamais committer automatiquement** — laisser le repo prêt, le
mentionner dans le rapport final (règle globale : commit uniquement sur
demande explicite).

## Step 3 — Extraire le contenu du PDF source

Via le conteneur partagé (mêmes outils que la compilation, `poppler-utils`) :

```bash
docker run --rm -v "<repo>:/workspace" -w /workspace cours-latex:latest \
  pdftotext -layout source.pdf source.txt
docker run --rm -v "<repo>:/workspace" -w /workspace cours-latex:latest \
  pdfimages -png source.pdf images/raw/img
```

Lire `source.txt` pour comprendre le découpage réel du support (chapitres/
sections tels que le prof les a organisés). Pour une page dense/complexe
(schéma illisible en texte), rendre la page en image pour l'inspecter :

```bash
docker run --rm -v "<repo>:/workspace" -w /workspace cours-latex:latest \
  pdftoppm -png -r 150 -f <page> -l <page> source.pdf /workspace/images/raw/page
```

## Step 4 — Proposer un découpage en chapitres et attendre validation

Présenter à l'utilisateur le découpage envisagé (liste de chapitres avec
un résumé d'une ligne chacun) et **attendre confirmation avant d'écrire
le moindre fichier de contenu** — les cours longs se traitent chapitre
par chapitre avec point d'étape, jamais en un seul passage silencieux.

## Step 5 — Rédiger chaque chapitre validé

Pour chaque chapitre, à partir de `examples/latex-chapter.tex` :
`chapitres/chapXX-nom.tex`, ajouté à `main.tex` via
`\input{chapitres/chapXX-nom}` dans l'ordre du cours.

Pour chaque notion du support :
- Reformuler intégralement le contenu — définitions, théorèmes,
  propriétés, exemples — dans les environnements de
  `examples/latex-preamble.sty` (`definition`, `theoreme`, `proposition`,
  `exemple`, `remarque`, `intuition`, `proof`).
- Ajouter une **intuition** non technique à chaque notion abstraite
  (analogie, reformulation informelle) — c'est le cœur de la demande
  "decortiquer le cours".
- Ajouter une **démonstration** (`proof`) uniquement si (a) elle est
  donnée dans le support — la reformuler clairement —, ou (b) elle est
  absente mais le résultat est **standard et certain** — dans ce cas
  seulement, rédiger la preuve standard. Sinon, écrire explicitement
  `\textit{Démonstration non fournie dans le support source.}` — ne
  jamais combler par une preuve inventée ou approximative.
- Recréer en **TikZ natif** (`tikzpicture`, bibliothèques déjà chargées :
  `arrows.meta, positioning, automata, calc, shapes.geometric`) les
  schémas techniques (automates, graphes, diagrammes commutatifs,
  architectures) — jamais une simple description textuelle à la place
  d'un schéma présent dans le support.
- Insérer via `\includegraphics` les images extraites à l'étape 3 pour
  tout ce qui n'est pas un schéma technique recréable (capture d'écran,
  photo, graphique de données complexe), avec légende.
- Ajouter les blocs de code avec `\begin{minted}{<langage>} ... \end{minted}`.
- Ajouter une entrée `\newglossaryentry{<label>}{name=..., description=...}`
  dans `glossaire.tex` pour chaque notion clé, référencée via `\gls{<label>}`
  dans le texte du chapitre.

## Step 6 — Compiler après chaque chapitre

Depuis le repo de cours (shell détecté au préalable) :

```bash
./compile.sh      # Bash/WSL
```
```powershell
.\compile.ps1      # PowerShell
```

Corriger toute erreur LaTeX avant de passer au chapitre suivant — ne
jamais accumuler plusieurs chapitres non vérifiés.

## Step 7 — Compilation finale et livraison

Compilation complète (latexmk gère automatiquement les passes multiples
et `makeglossaries` via `.latexmkrc`). Vérifier dans `main.log` l'absence
de `LaTeX Error`/ligne `!` — deux avertissements informationnels connus
et sans conséquence peuvent apparaître (legacy list code de babel-french,
absence de support `datatool` pour le français), voir
`docker/latex/README.md`. Envoyer le PDF final via SendUserFile.

## Guardrails

- **Jamais d'information inventée** : toute démonstration ou fait ajouté
  au-delà du support doit être un résultat standard et certain ; sinon,
  le signaler explicitement plutôt que combler le vide.
- **Jamais de schéma du support remplacé par du texte** : un diagramme
  présent dans les slides doit être recréé en TikZ ou extrait en image,
  jamais simplement décrit en prose à la place.
- **Ne jamais committer/pousser sans demande explicite.**
- **Ne jamais reconstruire l'image Docker implicitement** — la signaler
  manquante et proposer le build plutôt que de lancer un build de
  plusieurs minutes sans prévenir.
- Toujours détecter le shell actif avant de choisir `compile.sh` vs
  `compile.ps1`.
- Le contenu du cours est en français (exception explicite et assumée à
  la règle "code en anglais" — voir la note dans `## Goal`) ; tout le
  reste (noms de fichiers, commentaires LaTeX, scripts, Dockerfile) reste
  en anglais.

## Final report

- Chapitres traités (liste) et chemin du repo de cours.
- Chemin du PDF compilé.
- Notions ajoutées au glossaire.
- Tout passage marqué "démonstration non fournie dans le support source".
- Rappel explicite que le repo n'a pas été committé (sauf demande).
