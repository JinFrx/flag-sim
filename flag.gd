extends Spatial

# ==============================================================================

# === STRUCTURES DE DONNEES ===

class Strut:
	var k # coefficient de rigidite
	var d # coefficient de viscosite (damping)
	var l0
	var miIdx # tableau d'indices de la masse mi
	var mjIdx # tableau d'indices de la masse mj

class Face:
	var m0Idx
	var m1Idx
	var m2Idx
	var n # normale a la surface
	
class Mass:
	var massValue
	var x # position
	var v # vitesse
	var force
	var fixed

# ==============================================================================

# === PARAMETRES UTILISATEUR ===

# chemin dans l'arborescence du noeud Godot pour l'affichage de la geometrie du
# drapeau
export(NodePath) var geometryPath
export(NodePath) var guiPath

export(int, 2, 50) var NB_MASSES_W
export(int, 2, 50) var NB_MASSES_H
export(float, 0.001, 100) var M
export(float, 0, 10000) var K
export(float, 0, 100) var D
export(float, 0, 1) var Cd
export(float, 0, 1) var Cl

# ==============================================================================

# === PARAMETRES INTERNES ===

#var gravity = Vector3(0, -9.8, 0)
var wind = Vector3(5, -2, 0.5)
var tSimul = 0
var tMax = 100
var timeStep = 0.01
var n = 0
var eos = false

# ==============================================================================

# === VARIABLES ===

enum RenderMode { POINTS, LINES, TRIANGLES }
enum TextureNumber { TEXTURE_0,
					 TEXTURE_1,
					 TEXTURE_2,
					 TEXTURE_3,
					 TEXTURE_4,
					 TEXTURE_5 }

# noeud Godot pour l'affichage de la geometrie du drapeau
var geometry
# noeud Godot pour l'affichage des infos de simulation
var gui
var guiVisible
var renderMode
# materiau Godot de la surface
var surfaceMat
var texture
var textureNum
var rng

var struts = []
var faces = []
var masses = []

# ==============================================================================

# === FONCTIONS ===

func massIdx1D(idx2D):
	return idx2D[0] + idx2D[1] * NB_MASSES_W

func buildSpringNetwork():
	"""Definir le maillage du drapeau et construire le reseau de ressorts avec
	les masses, les struts et les faces.
	"""
	
	# --- Masses ---
		
	#var offsetX = float(NB_MASSES_W - 1) / 2
	#var offsetY = float(NB_MASSES_H - 1) / 2
	
	for j in range(NB_MASSES_H):
		for i in range(NB_MASSES_W):
			var m = Mass.new()
			
			m.massValue = M
			#m.massValue = M / (NB_MASSES_W * NB_MASSES_H)
			#m.x = Vector3(i - offsetX, -j + offsetY, 0)
			m.x = Vector3(i, -j, 0)
			m.v = Vector3.ZERO
			m.force = Vector3.ZERO
			m.fixed = false
			
			masses.append(m)
	
	# Masses fixes
	masses[massIdx1D([0, 0])].fixed = true
	#masses[massIdx1D([0, 1])].fixed = true
	masses[massIdx1D([0, NB_MASSES_H - 1])].fixed = true
	#masses[massIdx1D([0, NB_MASSES_H - 2])].fixed = true
	
	# --- Struts ---
	
	# Struts en largeur
	for j in range(NB_MASSES_H):
		for i in range(NB_MASSES_W - 1):
			var s = Strut.new()
			
			s.k = K
			s.d = D
			s.l0 = 1.0
			s.miIdx = [i, j]
			s.mjIdx = [i + 1, j]
			
			struts.append(s)
	
	# Struts en hauteur
	for j in range(NB_MASSES_H - 1):
		for i in range(NB_MASSES_W):
			var s = Strut.new()
			
			s.k = K
			s.d = D
			s.l0 = 1.0
			s.miIdx = [i, j]
			s.mjIdx = [i, j + 1]
			
			struts.append(s)
	
	# Struts diagonales
	for j in range(NB_MASSES_H - 1):
		for i in range(NB_MASSES_W - 1):
			var s1 = Strut.new()
			
			s1.k = K * 1.414
			s1.d = D * 1.414
			s1.l0 = 1.414
			s1.miIdx = [i, j]
			s1.mjIdx = [i + 1, j + 1]
			
			struts.append(s1)
			
			#var s2 = Strut.new()
			
			#s2.k = K * 1.414
			#s2.d = D * 1.414
			#s2.l0 = 1.414
			#s2.miIdx = [i + 1, j]
			#s2.mjIdx = [i, j + 1]
			
			#struts.append(s2)
	
	# --- Faces ---
	
	for j in range(NB_MASSES_H - 1):
		for i in range(NB_MASSES_W - 1):
			var f1 = Face.new()
			
			f1.m0Idx = [i, j]
			f1.m1Idx = [i + 1, j]
			f1.m2Idx = [i + 1, j + 1]
			f1.n = Vector3.BACK
			
			faces.append(f1)
			
			var f2 = Face.new()
			
			f2.m0Idx = [i, j]
			f2.m1Idx = [i + 1, j + 1]
			f2.m2Idx = [i, j + 1]
			f2.n = Vector3.BACK
			
			faces.append(f2)
	
	print('--- SIMULATION DEBUG INFOS ---')
	print(masses.size(), ' masses.')
	print(struts.size(), ' struts.')
	print(faces.size(), ' faces.')

func computeAllForces():
	"""Calculer la force cumulee des forces externes, calculer les forces de
	ressort et de viscosite et calculer les forces d'aerodynamisme des faces.
	"""
	
	# --- Cumulee des forces externes ---
	
	#"""
	for m in masses:
		m.force = -Cd * (m.v - wind)
	#"""
	
	# --- Forces de ressort et de viscosite ---
	
	for s in struts:
		var mi = masses[massIdx1D(s.miIdx)]
		var mj = masses[massIdx1D(s.mjIdx)]
		
		var vectij = mj.x - mi.x
		var dirij = vectij.normalized()
		
		# force de rappel
		var l = vectij.length()
		var fsi = s.k * (l - s.l0) * dirij
		
		# force de viscosite
		var vDiff = mj.v - mi.v
		var fdi = s.d * vDiff.dot(dirij) * dirij
		
		mi.force += fsi + fdi
		# troisieme loi de Newton
		mj.force += -fsi - fdi
	
	# --- Distribution des forces externes d'aerodynamisme ---
	
	for f in faces:
		var m0 = masses[massIdx1D(f.m0Idx)]
		var m1 = masses[massIdx1D(f.m1Idx)]
		var m2 = masses[massIdx1D(f.m2Idx)]
		
		var vect01 = m1.x - m0.x
		var vect12 = m2.x - m1.x
		var vect20 = m0.x - m2.x
		var vect10 = -vect01
		var vect21 = -vect12
		var vect02 = -vect20
		
		f.n = vect01.cross(vect21).normalized()
		
		var vf = (m0.v + m1.v + m2.v) / 3.0
		
		# TODO : corriger le probleme avec la methode du livre (question : ou
		# est le probleme ? )
		"""
		# vitesse relative du triangle dans l'air
		var vr = vf - wind
		var area = 0.5 * vect10.cross(vect12).dot(f.n)
		var effectArea = area * f.n.dot(vr)
		
		# force de resistance a l'air
		var fd = -Cd * effectArea * vr
		
		# force de portance du vent
		var insideCrossp = f.n.cross(vr).normalized()
		var outsideCrossp = vr.cross(insideCrossp)
		var fl = -Cl * effectArea * outsideCrossp
		
		var ff = fd + fl
		
		# angle en degrees sur m0
		var dot0102 = vect01.dot(vect02)
		var vect01Mod = vect01.length()
		var vect02Mod = vect02.length()
		var alpha0 = acos(dot0102 / (vect01Mod * vect02Mod)) * PI / 180.0
		
		# angle en degrees sur m1
		var dot1210 = vect12.dot(vect10)
		var vect12Mod = vect12.length()
		var vect10Mod = vect10.length()
		var alpha1 = acos(dot1210 / (vect12Mod * vect10Mod)) * PI / 180.0
		
		# angle en degrees sur m2
		var dot2021 = vect20.dot(vect21)
		var vect20Mod = vect20.length()
		var vect21Mod = vect21.length()
		var alpha2 = acos(dot2021 / (vect20Mod * vect21Mod)) * PI / 180.0
		
		m0.force += ff * (alpha0 / 180.0)
		m1.force += ff * (alpha1 / 180.0)
		m2.force += ff * (alpha2 / 180.0)
		"""
		
		#"""
		var vr = wind - vf
		var ff = (f.n * f.n.dot(vr)) / 3.0
		
		m0.force += ff
		m1.force += ff
		m2.force += ff
		#"""
	
func eulerIntegration():
	"""Mettre a jour les valeurs de position et de vitesse.
	"""
	
	for m in masses:
		if not m.fixed:
			var a = m.force / m.massValue
			
			m.v = m.v + timeStep * a
			m.x = m.x + timeStep * m.v

func loadTexture():
	"""Charger une texture.
	"""
	
	if textureNum == TextureNumber.TEXTURE_0:
		texture = load("res://drapeaux/drapeauFrancais.jpg")
	elif textureNum == TextureNumber.TEXTURE_1:
		texture = load("res://drapeaux/drapeauAmericain.jpg")
	elif textureNum == TextureNumber.TEXTURE_2:
		texture = load("res://drapeaux/drapeauEspagnol.jpg")
	elif textureNum == TextureNumber.TEXTURE_3:
		texture = load("res://drapeaux/drapeauAlgerien.jpg")
	elif textureNum == TextureNumber.TEXTURE_4:
		texture = load("res://drapeaux/drapeauJaponais.jpg")
	elif textureNum == TextureNumber.TEXTURE_5:
		texture = load("res://drapeaux/drapeauCapitalisme.jpg")
	
func drawFlagGeometry():
	"""Afficher le maillage du drapeau.
	"""
	
	geometry.clear()
	
	if renderMode == RenderMode.POINTS:
		surfaceMat.flags_unshaded = true
		surfaceMat.flags_vertex_lighting = false
		surfaceMat.vertex_color_use_as_albedo = true
		surfaceMat.albedo_texture = null
		
		geometry.begin(Mesh.PRIMITIVE_POINTS)
		
		geometry.set_color(Color.white)
		
		for m in masses:
			geometry.add_vertex(m.x)
		
		geometry.end()
	elif renderMode == RenderMode.LINES:
		surfaceMat.flags_unshaded = true
		surfaceMat.flags_vertex_lighting = false
		surfaceMat.vertex_color_use_as_albedo = true
		surfaceMat.albedo_texture = null
		
		geometry.begin(Mesh.PRIMITIVE_LINES)
		
		geometry.set_color(Color.white)
		
		for s in struts:
			var mi = masses[massIdx1D(s.miIdx)]
			var mj = masses[massIdx1D(s.mjIdx)]
			
			geometry.add_vertex(mi.x)
			geometry.add_vertex(mj.x)
		
		geometry.end()
	elif renderMode == RenderMode.TRIANGLES:
		surfaceMat.flags_unshaded = false
		surfaceMat.flags_vertex_lighting = true
		surfaceMat.vertex_color_use_as_albedo = false
		surfaceMat.albedo_texture = texture
		
		var textureSize = texture.get_size()
		
		geometry.begin(Mesh.PRIMITIVE_TRIANGLES)
		
		for f in faces:
			var m0 = masses[massIdx1D(f.m0Idx)]
			var m1 = masses[massIdx1D(f.m1Idx)]
			var m2 = masses[massIdx1D(f.m2Idx)]
			
			geometry.set_normal(f.n)
			geometry.set_uv(Vector2(float(f.m0Idx[0]) / NB_MASSES_W,
									float(f.m0Idx[1]) / NB_MASSES_H))
			geometry.add_vertex(m0.x)
			
			geometry.set_normal(f.n)
			geometry.set_uv(Vector2(float(f.m1Idx[0]) / NB_MASSES_W,
									float(f.m1Idx[1]) / NB_MASSES_H))
			geometry.add_vertex(m1.x)
			
			geometry.set_normal(f.n)
			geometry.set_uv(Vector2(float(f.m2Idx[0]) / NB_MASSES_W,
									float(f.m2Idx[1]) / NB_MASSES_H))
			geometry.add_vertex(m2.x)
		
		geometry.end()

func drawGUI():
	if guiVisible:
		gui.get_child(0).show()
	else:
		gui.get_child(0).hide()
	
# ==============================================================================

func _ready():
	geometry = get_node(geometryPath)
	surfaceMat = geometry.get_material_override()
	gui = get_node(guiPath)
	
	guiVisible = true
	renderMode = 2
	textureNum = 0
	rng = RandomNumberGenerator.new()
	
	buildSpringNetwork()
	loadTexture()

func _process(_delta):
	# DEBUT SIMULATION
	
	if tSimul < tMax:
		computeAllForces()
		eulerIntegration()
		
		n += 1
		tSimul = n * timeStep
	
	if not eos && tSimul >= tMax:
		print('\nSimulation ended in ', n, ' step(s).')
		eos = true
	
	drawFlagGeometry()
	drawGUI()
	
	# FIN SIMULATION

func _unhandled_input(event):
	"""Traiter les evenements clavier.
	"""
	
	if event is InputEventKey:
		if event.pressed:
			if event.scancode == KEY_I:
				# afficher ou non l'interface des infos de simulation
				guiVisible = !guiVisible
			elif event.scancode == KEY_M:
				# changer le mode de rendu
				renderMode = (renderMode + 1) % 3
			elif event.scancode == KEY_T and renderMode == 2:
				# changer de texture
				textureNum = (textureNum + 1) % 6
				loadTexture()
			elif event.scancode == KEY_SPACE:
				# changer la vitesse du vent de facon aleatoire
				wind = Vector3(stepify(rng.randf_range(2.0, 10.0), 0.1),
							   stepify(rng.randf_range(-10.0, 10.0), 0.1),
							   stepify(rng.randf_range(-5.0, 5.0), 0.1));
			elif event.scancode == KEY_ESCAPE:
				# quitter la simulation avec la touche ECHAP
				get_tree().quit()
