extends CanvasLayer

# ==============================================================================

export(NodePath) var flagPath

var flag
var nbMassesW_label
var nbMassesH_label
var massValue_label
var k_label
var d_label
var cd_label
var cl_label
var wind_label
var tMax_label
var timeStep_label
var tSimul_label

# ==============================================================================

func displayGui():
	nbMassesW_label.text = "Nb Masses (Width) : " + str(flag.NB_MASSES_W)
	
	nbMassesH_label.text = "Nb Masses (Height) : " + str(flag.NB_MASSES_H)
	
	massValue_label.text = "Mass value : " + str(flag.M)
	
	k_label.text = "Strength constant (k) : " + str(flag.K)
	
	d_label.text = "Damping constant (d) : " + str(flag.D)
	
	cd_label.text = "Air drag coef (Cd) : " + str(flag.Cd)
	
	cl_label.text = "Lift coef (Cl) : " + str(flag.Cl)
	
	tMax_label.text = "tMax : " + str(flag.tMax)
	
	timeStep_label.text = "timeStep : " + str(flag.timeStep)
	
func updateGui():
	wind_label.text = "Wind velocity : " + str(flag.wind)
	
	tSimul_label.text = "time : " + str(flag.tSimul)

# ==============================================================================
	
# Called when the node enters the scene tree for the first time.
func _ready():
	flag = get_node(flagPath)
	nbMassesW_label = get_node("Control/Nb_Masses_W_Label")
	nbMassesH_label = get_node("Control/Nb_Masses_H_Label")
	massValue_label = get_node("Control/Mass_Value_Label")
	k_label = get_node("Control/Strength_Cst_Label")
	d_label = get_node("Control/Damping_Cst_Label")
	cd_label = get_node("Control/Air_Drag_Coef_Label")
	cl_label = get_node("Control/Lift_Coef_Label")
	wind_label = get_node("Control/Wind_Label")
	tMax_label = get_node("Control/TMax_Label")
	timeStep_label = get_node("Control/Time_Step_Label")
	tSimul_label = get_node("Control/TSimul_Label")
	
	displayGui()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	updateGui()
