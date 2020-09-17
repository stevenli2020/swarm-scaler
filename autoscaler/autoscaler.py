#!/usr/bin/python
import os, string, random, time, socket, thread, sys, commands, json

LEADER_ONLINE = True
SCALING = False
scaling_queue = []

def scaler():
	global scaling_queue
	while 1:
		try:
			# print scaling_queue
			if len(scaling_queue) > 0:
				(SERVICE,REPLICAS) = scaling_queue.pop(0)
				EXEC("docker service scale "+SERVICE+"="+str(REPLICAS))+"\n"
				print "Service '"+SERVICE+"' scaled to "+str(REPLICAS)
		except:
			pass
		time.sleep(2)	

def UDP_ECHO():
	while 1:
		try:
			sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
			server = ('0.0.0.0', 733)
			sock.bind(server)
			print("Echo service started on 0.0.0.0:733")
			while True:
				payload, client_address = sock.recvfrom(8)
				print("Echoing data back to " + str(client_address))
				sent = sock.sendto(payload, client_address)
		except:
			print("Service stopped")
			time.sleep(2)

			
def EXEC(CMD):
	ERR_SUCCESS,OUTPUT = commands.getstatusoutput(CMD)
	return OUTPUT

def CHECK_LEADER():
	global LEADER_ONLINE, CONF
	while 1: 
		print "Check if leader node is online"
		try:
			if EXEC("echo 'ALOHA' | nc -w 1 -u "+CONF['LEADER_NODE']+" 733").strip() == "ALOHA":
				LEADER_ONLINE = True
				print "- leader node is online"
			else: 
				LEADER_ONLINE = False
				print "- leader node is offline"
		except:
			pass
		time.sleep(30)

def SERVICE_SCALER(SERVICE):
	global LEADER_ONLINE, CONF
	EC = [0]*int(SERVICE['MA_POINTS'])
	while 1:
		time.sleep(SERVICE['SAMPLE_INTERVAL'])
		if (CONF['NODE_MODE'] != "LEADER") and LEADER_ONLINE:
			continue
		try:
			SERVICE_REPLICAS = int(EXEC("docker service ps "+SVC['SERVICE_NAME']+" -f desired-state=Running -q | wc -l"))
		except:
			print "Service '"+SVC['SERVICE_NAME']+"' not found"
			continue
		try:
			ESTABLISHED_CONNECTIONS = int(EXEC("nsenter -t $(docker inspect -f '{{.State.Pid}}' $(docker ps --format {{.Names}} | grep "+SERVICE['SERVICE_NAME']+" | head -1)) -n netstat -pant | grep ESTA | wc -l"))
		except:
			ESTABLISHED_CONNECTIONS = 0
		EC.append(ESTABLISHED_CONNECTIONS)
		EC.pop(0) 
		EC_AVG = sum(EC) / SERVICE['MA_POINTS']
		# print "SERVICE_REPLICAS="+str(SERVICE_REPLICAS)+"; ESTABLISHED_CONNECTIONS="+','.join(map(str,EC))+"; AVG="+str(EC_AVG)  
		print SERVICE['SERVICE_NAME']+"="+str(SERVICE_REPLICAS)+"; CONN="+str(EC_AVG)  
		if EC_AVG > SERVICE['CONN_THRESHOLD_H']:
			print "Scaling up triggered by upper threshold"
			thread.start_new_thread(SERVICE_SCALE_UP,(SERVICE,SERVICE_REPLICAS))
		elif (EC_AVG < SERVICE['CONN_THRESHOLD_L']) and (SERVICE_REPLICAS > SERVICE['BASE_REP_COUNT']):
			print "Scaling down triggered by lower threshold"
			thread.start_new_thread(SERVICE_SCALE_DN,(SERVICE,SERVICE_REPLICAS))		
			
def SERVICE_SCALE_UP(SVC, REP):
	global SCALING, scaling_queue
	if SCALING:
		print "Within scaling stabilization time, skip"
		return
	SCALING = True
	if REP+2 <= SVC['MAX_REP_COUNT']:
		scaling_queue.append((SVC['SERVICE_NAME'],REP+2))
	else:
		print "Scaling target out of range"
	time.sleep(SVC['STABLIZATION_TIME'])
	SCALING = False
	print "Scaling up completed"

def SERVICE_SCALE_DN(SVC, REP):
	global SCALING, scaling_queue
	if SCALING:
		print "Within scaling stabilization time, skip"
		return
	SCALING = True
	if REP-2 >= SVC['BASE_REP_COUNT']:
		scaling_queue.append((SVC['SERVICE_NAME'],REP-2))
	else:
		print "Scaling target out of range"	
	time.sleep(SVC['STABLIZATION_TIME'])
	SCALING = False	
	print "Scaling down completed"
	
	
#=====================================================

with open("/etc/autoscaler/config", 'r') as f:
	CONF = json.loads(f.read())
	
if CONF["NODE_MODE"] == "LEADER":
	thread.start_new_thread(UDP_ECHO,())
else:
	thread.start_new_thread(CHECK_LEADER,())

for SVC in CONF["AUTOSCALE"]:
	print SVC['SERVICE_NAME']
	thread.start_new_thread(SERVICE_SCALER,(SVC,))
	
thread.start_new_thread(scaler,())	
while 1:
	time.sleep(2)
	
	
	
	
	
	
	
	