# Flag simulation with wind action using spring-damper-mass system

<p align=center>
  <img src="https://github.com/JinFrx/flag-sim/blob/main/simulation_drapeau.gif" alt="showcase image" style="width: 650px; max-width: 100%; height: auto" title="Click to enlarge picture" />
</p>

## Description

*FR*

Projet réalisé dans un cadre universitaire (2021).

Une simulation de drapeau implémentée avec le moteur de jeu Godot.

Le maillage du drapeau est construit suivant le *système masse-ressort-amortisseur*.
L'action du vent sur le drapeau est implémentée en calculant les forces de vent et de trainée d'air qui s'appliquent sur les faces du maillage via les normales.

L'application permet à l'utilisateur d'intéragir avec la simulation en appuyant sur différentes touches du clavier:

- Appuyer sur **I** pour cacher/montrer les paramètres de simulation
- Appuyer sur **M** pour changer le mode de rendu entre Points, Arêtes et Faces
- Appuyer sur **T** pour changer la texture du drapeau
- Appuyer sur **Espace** pour changer de manière aléatoire la velocité du vent (direction et puissance)

---

*EN*

A simulation of a flag made with Godot Engine, as part of a university project (2021).

The flag is modelised with a *spring-damper-mass system*.
The action of wind on the flag is implemented by computing wind and air drag forces that act on the mesh faces through normals.

This application allows the user to interact with the simulation by pressing some keys:

- Press **I** to hide/show simulation parameters information
- Press **M**  to change the rendering mode between Points, Edges and Faces
- Press **T** to change the texture of the flag
- Press **Spacebar** to randomly change the velocity of the wind (direction and power)

:warning: WARNING :warning:

Unfortunately, I'm French! ... well I would rather say "Unfortunately, I'm using an AZERTY keyboard".
I guess Godot does automatically the connection between all layouts, but be aware of that if it isn't the case (specially for the M key).
