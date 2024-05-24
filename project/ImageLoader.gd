extends Control
const MODULE_NAME = "ImageLoader"
var ImageBlockPacked = preload("res://Image.tscn")
var logger = LogWriter.new()

# data from csv file
var dupeData = []
# storage for generated nodes
var imageNodes = []
# holding onto importand reference nodes
var imageBoxNode
var labelNode
# Indicates the 0th index of the current group
# if on group 2 of [0,0,1,1,2,2,3,3,3], index should be 4
var currentIndex = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	labelNode = get_node("Label")
	imageBoxNode = get_node("ImageBox")
	dupeData = Utils.importCSV(Data.CSV_FILE_PATH, Data.CSV_OPTIONS)
	if dupeData[0] != Data.CSV_FOOTPRINT:
		printerr("File does not match expected footprint")
		return
	# Remove CSV header, it will only get in the way
	dupeData.pop_front()
	loadImageNodeGroupByStartingIndex(currentIndex)

func _process(delta):
	pass

func getIndexListForGroupId(id: int):
	var list = []
	for i in range(dupeData.size()):
		if dupeData[i]["Group ID"] == id:
			list.append(i)
	return list

func fileExistsForIndex(id: int):
	var dict = dupeData[id]
	var filepath = dict["Folder"] + "/" + dict["Filename"]
	return Utils.fileExistsAtLocation(filepath)

func loadImageNodeGroupByStartingIndex(startingIndex: int):
	var index = startingIndex
	var currentGroup = dupeData[index]["Group ID"]
	var groupIndices = []
	groupIndices.append(startingIndex)
	while(index+1 < dupeData.size() and dupeData[index+1]["Group ID"] == currentGroup):
		# this should usually only run once
		groupIndices.append(index+1)
		index+=1
	for i in groupIndices:
		createImageNodeByIndex(i)
	pass

func createImageNodeByIndex(index:int):
	var newNode = ImageBlockPacked.instantiate()
	var dict = dupeData[index]
	var imagePath = dict["Folder"] + "/" + dict["Filename"]
	newNode.setImgProperties(imagePath)
	imageBoxNode.addImageNode(newNode)
	# add new node to list
	imageNodes.append(newNode)
	pass

func clearImageNodes():
	for n in imageNodes:
		n.queue_free()
	imageNodes = []
	pass

func getNextGroupZeroIndex(currentIndex: int):
	var currentGroup = dupeData[currentIndex]["Group ID"]
	var index = currentIndex + 1
	var foundNewIndex:bool = false
	while not foundNewIndex and index != currentIndex:
		if len(dupeData)-1 < index:
			index = 0
		if dupeData[index]["Group ID"] != currentGroup:
			var groupIndexList = getIndexListForGroupId(dupeData[index]["Group ID"])
			if groupIndexList.any(func(i): return fileExistsForIndex(i)):
				# if there is any file that exists for this group, accept it
				foundNewIndex = true
				break
		index += 1
	if foundNewIndex:
		return index
	else:
		# this will happen if there is only one valid group in dupedata
		return null

func getPrevGroupZeroIndex(currentIndex: int):
	var currentGroup = dupeData[currentIndex]["Group ID"]
	var index = currentIndex - 1
	var foundNewIndex:bool = false
	while not foundNewIndex and index != currentIndex:
		if 0 > index:
			index = dupeData.size() - 1
		var thisGroupId = dupeData[index]["Group ID"]
		var beforeThisGroupId = dupeData[index-1]["Group ID"] if index>0 else dupeData[-1]["Group ID"]
		# we have reached the correct index if it has a different group and it is the earliest instance of that group
		if thisGroupId != currentGroup and thisGroupId != beforeThisGroupId:
			var groupIndexList = getIndexListForGroupId(dupeData[index]["Group ID"])
			if groupIndexList.any(func(i): return fileExistsForIndex(i)):
				# if there is any file that exists for this group, accept it
				foundNewIndex = true
				break
		index -= 1
	if foundNewIndex:
		return index
	else:
		# this will happen if there is only one valid group in dupedata
		return null

func _on_left_pressed()->void:
	clearImageNodes()
	# set previous group index or null if no other group exists
	currentIndex = getPrevGroupZeroIndex(currentIndex)
	loadImageNodeGroupByStartingIndex(currentIndex)
	setLabel("%s: %s" % [str(currentIndex), dupeData[currentIndex]])
	pass

func _on_right_pressed()->void:
	clearImageNodes()
	# set next group index or null if no other group exists
	currentIndex = getNextGroupZeroIndex(currentIndex)
	loadImageNodeGroupByStartingIndex(currentIndex)
	setLabel("%s: %s" % [str(currentIndex), dupeData[currentIndex]])
	pass

func setLabel(str: String)->void:
	labelNode.text = str
	pass
