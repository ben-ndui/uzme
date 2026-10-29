#!/usr/bin/env python3
"""Recopie le contexte commun de 00-SYSTEME.md dans la Partie 1 de chaque lot.

Chaque fichier de lot est autonome : Claude Design reçoit un seul fichier. Le
prix de cette autonomie est la duplication du socle, que ce script maintient.
Idempotent, il remplace la Partie 1 et ne touche jamais à la Partie 2.
"""
import glob
import io
import sys

SOCLE = '00-SYSTEME.md'
SEP = '\n---\n\n# Partie 2, Le lot : '


def socle_body():
    """Le corps de 00-SYSTEME.md, sans son titre ni sa note d'introduction."""
    lines = io.open(SOCLE, encoding='utf-8').read().split('\n')
    body, in_intro = [], True
    for line in lines[1:]:
        if in_intro:
            if line.startswith('>') or not line.strip():
                continue
            in_intro = False
        body.append(line)
    return '\n'.join(body).strip()


def main():
    socle = socle_body()
    lots = sorted(f for f in glob.glob('[0-9][0-9]-*.md') if f != SOCLE)
    if not lots:
        sys.exit('Aucun fichier de lot trouve, lancer depuis design/prompts/.')

    for path in lots:
        text = io.open(path, encoding='utf-8').read()
        if SEP not in text:
            print(f'  ignore (structure inattendue) : {path}')
            continue
        head, tail = text.split(SEP, 1)
        titre = head.split('\n', 1)[0]
        note = head.split('\n---\n', 1)[0].split('\n', 1)[1].strip()
        rebuilt = (
            f'{titre}\n\n{note}\n\n---\n\n'
            f'# Partie 1, Contexte commun (identique pour tous les lots)\n\n'
            f'{socle}\n{SEP}{tail}'
        )
        io.open(path, 'w', encoding='utf-8').write(rebuilt)
        print(f'  socle propage : {path}')

    print(f'{len(lots)} lots mis a jour.')


if __name__ == '__main__':
    main()
