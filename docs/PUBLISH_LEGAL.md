# Publish Privacy Policy & Terms (GitHub Pages)

Play Console needs a **public HTTPS Privacy Policy URL**.

Prepared site files live in this repo at:

`docs/github_pages/`

(`index.html`, `privacy.html`, `terms.html`, markdown copies)

## One-time setup on your machine

The cloud agent cannot push to `zlobocki/mine_puzzle` (no write permission). Copy the files yourself:

```bash
git clone https://github.com/zlobocki/mine_puzzle.git
cd mine_puzzle
# Copy from the Boomblocks checkout:
cp /path/to/Boomblocks/docs/github_pages/* .
git add -A
git commit -m "Add Privacy Policy and Terms of Use for Mine Puzzle"
git push origin main
```

Then enable Pages:

1. Open https://github.com/zlobocki/mine_puzzle/settings/pages  
2. **Source:** Deploy from a branch  
3. Branch: `main` / folder: `/ (root)` → Save  

After a minute, these URLs should work:

- https://zlobocki.github.io/mine_puzzle/privacy.html  ← use in Play Console  
- https://zlobocki.github.io/mine_puzzle/terms.html  
- https://zlobocki.github.io/mine_puzzle/

## Play Console field

**App content → Privacy policy** → paste:

`https://zlobocki.github.io/mine_puzzle/privacy.html`
