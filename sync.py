#!/usr/bin/python -tt

# Control BZFlag tanks remotely with synchronous communication.

from __future__ import division
import math, sys, socket, time

class BZRC:
    '''Class which handles queries and responses with remote control bots.'''

    def __init__(self, host, port, debug=False):
        '''Given a hostname and port number, connect to the RC tanks.'''

        self.debug = debug

        # Note that AF_INET and SOCK_STREAM are defaults.
        sock = socket.socket()
        sock.connect((host, port))
        # Make a line-buffered "file" from the socket.
        self.conn = sock.makefile(bufsize=1)

        self.handshake()

    def close(self):
        '''Close the socket.'''
        self.conn.close()

    def read_arr(self):
        '''Read a response from the RC tanks as an array split on
        whitespace.'''

        line = self.conn.readline()
        if self.debug:
            print 'Received: %s' % line.split()
        return line.split()

    def sendline(self, line):
        '''Send a line to the RC tanks.'''

        print >>self.conn, line

    def die_confused(self, expected, got_arr):
        '''When we think the RC bots should have responded differently, call
        this method with a string explaining what should have been sent and
        with the array containing what was actually sent.'''

        raise UnexpectedResponse(expected, ' '.join(got_arr))

    def handshake(self):
        '''Perform the handshake with the remote bots.'''

        line = self.read_arr()
        if line != ['bzrobots', '1']:
            self.die_confused('bzrobots 1', line)
        print >>self.conn, 'agent 1'

    def read_ack(self):
        '''Expect an "ack" line from the remote tanks.
        
        Raise an UnexpectedResponse exception if we get something else.'''

        line = self.read_arr()
        if line[0] != 'ack':
            self.die_confused('ack', line)

    def read_bool(self):
        '''Expect a boolean response from the remote tanks.
        
        Return True or False in accordance with the response.  Raise an
        UnexpectedResponse exception if we get something else.'''

        line = self.read_arr()
        if line[0] == 'ok':
            return True
        elif line[0] == 'fail':
            return False
        else:
            self.die_confused('ok or fail', line)

    def read_teams(self):
        line = self.read_arr()
        if line[0] != 'begin':
            self.die_confused('begin', line)

        teams = []
        while True:
            line = self.read_arr()
            if line[0] == 'team':
                team = Answer()
                team.color = line[1]
                team.count = float(line[2])
                team.base = [(float(x), float(y)) for (x, y) in
                        zip(line[3:11:2], line[4:11:2])]
                teams.append(team)
            elif line[0] == 'end':
                break
            else:
                self.die_confused('team or end', line)
        return teams

    def read_obstacles(self):
        line = self.read_arr()
        if line[0] != 'begin':
            self.die_confused('begin', line)

        obstacles = []
        while True:
            line = self.read_arr()
            if line[0] == 'obstacle':
                obstacle = [(float(x), float(y)) for (x, y) in
                        zip(line[1::2], line[2::2])]
                obstacles.append(obstacle)
            elif line[0] == 'end':
                break
            else:
                self.die_confused('obstacle or end', line)
        return obstacles

    def read_flags(self):
        line = self.read_arr()
        if line[0] != 'begin':
            self.die_confused('begin', line)

        flags = []
        while True:
            line = self.read_arr()
            if line[0] == 'flag':
                flag = Answer()
                flag.color = line[1]
                flag.poss_color = line[2]
                flag.x = float(line[3])
                flag.y = float(line[4])
                flags.append(flag)
            elif line[0] == 'end':
                break
            else:
                self.die_confused('flag or end', line)
        return flags

    def read_shots(self):
        line = self.read_arr()
        if line[0] != 'begin':
            self.die_confused('begin', line)

        shots = []
        while True:
            line = self.read_arr()
            if line[0] == 'shot':
                shot = Answer()
                shot.x = float(line[1])
                shot.y = float(line[2])
                shot.vx = float(line[3])
                shot.vy = float(line[4])
                shots.append(shot)
            elif line[0] == 'end':
                break
            else:
                self.die_confused('shot or end', line)
        return shots

    def read_mytanks(self):
        line = self.read_arr()
        if line[0] != 'begin':
            self.die_confused('begin', line)

        tanks = []
        while True:
            line = self.read_arr()
            if line[0] == 'mytank':
                tank = Answer()
                tank.index = int(line[1])
                tank.callsign = line[2]
                tank.status = line[3]
                tank.shots_avail = int(line[4])
                tank.time_to_reload = float(line[5])
                tank.flag = line[6]
                tank.x = float(line[7])
                tank.y = float(line[8])
                tank.angle = float(line[9])
                tank.vx = float(line[10])
                tank.vy = float(line[11])
                tank.angvel = float(line[12])
                tanks.append(tank)
            elif line[0] == 'end':
                break
            else:
                self.die_confused('mytank or end', line)
        return tanks

    def read_othertanks(self):
        line = self.read_arr()
        if line[0] != 'begin':
            self.die_confused('begin', line)

        tanks = []
        while True:
            line = self.read_arr()
            if line[0] == 'othertank':
                tank = Answer()
                tank.callsign = line[1]
                tank.color = line[2]
                tank.status = line[3]
                tank.flag = line[4]
                tank.x = float(line[5])
                tank.y = float(line[6])
                tank.angle = float(line[7])
                tanks.append(tank)
            elif line[0] == 'end':
                break
            else:
                self.die_confused('othertank or end', line)
        return tanks

    def read_constants(self):
        line = self.read_arr()
        if line[0] != 'begin':
            self.die_confused('begin', line)

        constants = {}
        while True:
            line = self.read_arr()
            if line[0] == 'constant':
                constants[line[1]] = line[2]
            elif line[0] == 'end':
                break
            else:
                self.die_confused('constant or end', line)
        return constants

    # Commands:

    def shoot(self, index):
        '''Perform a shoot request.'''

        self.sendline('shoot %s' % index)
        self.read_ack()
        return self.read_bool()

    def speed(self, index, value):
        '''Set the desired speed to the specified value.'''

        self.sendline('speed %s %s' % (index, value))
        self.read_ack()
        return self.read_bool()

    def angvel(self, index, value):
        '''Set the desired angular velocity to the specified value.'''

        self.sendline('angvel %s %s' % (index, value))
        self.read_ack()
        return self.read_bool()

    def accelx(self, index, value):
        '''Set the desired x acceleration to the specified value.'''

        self.sendline('accelx %s %s' % (index, value))
        self.read_ack()
        return self.read_bool()

    def accely(self, index, value):
        '''Set the desired x acceleration to the specified value.'''

        self.sendline('accely %s %s' % (index, value))
        self.read_ack()
        return self.read_bool()

    # Information Requests:

    def get_teams(self):
        '''Request a list of teams.'''

        self.sendline('teams')
        self.read_ack()
        return self.read_teams()

    def get_obstacles(self):
        '''Request a list of obstacles.'''

        self.sendline('obstacles')
        self.read_ack()
        return self.read_obstacles()

    def get_flags(self):
        '''Request a list of flags.'''

        self.sendline('flags')
        self.read_ack()
        return self.read_flags()

    def get_shots(self):
        '''Request a list of shots.'''

        self.sendline('shots')
        self.read_ack()

    def get_mytanks(self):
        '''Request a list of our robots.'''

        self.sendline('mytanks')
        self.read_ack()
        return self.read_mytanks()

    def get_othertanks(self):
        '''Request a list of tanks that aren't our bots.'''

        self.sendline('othertanks')
        self.read_ack()
        return self.read_othertanks()

    def get_constants(self):
        '''Request a dictionary of game constants.'''

        self.sendline('constants')
        self.read_ack()
        return self.read_constants()

    # Optimized queries

    def get_lots_o_stuff(self):
        '''Network-optimized request for mytanks, othertanks, flags, and shots.

        Returns a tuple with the four results.'''

        self.sendline('mytanks')
        self.sendline('othertanks')
        self.sendline('flags')
        self.sendline('shots')

        self.read_ack()
        mytanks = self.read_mytanks()
        self.read_ack()
        othertanks = self.read_othertanks()
        self.read_ack()
        flags = self.read_flags()
        self.read_ack()
        shots = self.read_shots()

        return (mytanks, othertanks, flags, shots)

    def do_commands(self, commands):
        '''Send commands for a bunch of tanks in a network-optimized way.'''

        for cmd in commands:
            self.sendline('speed %s %s' % (cmd.index, cmd.speed))
            self.sendline('angvel %s %s' % (cmd.index, cmd.angvel))
            if cmd.shoot:
                self.sendline('shoot %s' % cmd.index)

        results = []
        for cmd in commands:
            self.read_ack()
            result_speed = self.read_bool()
            self.read_ack()
            result_angvel = self.read_bool()
            if cmd.shoot:
                self.read_ack()
                result_shoot = self.read_bool()
            else:
                result_shoot = False
            results.append( (result_speed, result_angvel, result_shoot) )
        return results


class Answer(object):
    '''BZRC returns an Answer for things like tanks, obstacles, etc.

    You should probably write your own code for this sort of stuff.  We
    created this class just to keep things short and sweet.'''

    pass

class Command(object):
    '''Class for setting a command for a bot.'''

    def __init__(self, index, speed, angvel, shoot):
        self.index = index
        self.speed = speed
        self.angvel = angvel
        self.shoot = shoot

class UnexpectedResponse(Exception):
    '''Exception raised when the BZRC gets confused by a bad response.'''

    def __init__(self, expected, got):
        self.expected = expected
        self.got = got

    def __str__(self):
        return 'BZRC: Expected "%s".  Instead got "%s".' % (self.expected,
                self.got)

def normalize_angle(angle):
    '''Make any angle be between +/- pi.'''

    angle -= 2 * math.pi * int (angle / (2 * math.pi))
    if angle <= -math.pi:
        angle += 2 * math.pi
    elif angle > math.pi:
        angle -= 2 * math.pi
    return angle


########################################################################

# Process CLI arguments.

try:
    execname, host, port = sys.argv
except ValueError:
    execname = sys.argv[0]
    print >>sys.stderr, '%s: incorrect number of arguments' % execname
    print >>sys.stderr, 'usage: %s hostname port' % sys.argv[0]
    sys.exit(-1)

# Connect.

#bzrc = BZRC(host, int(port), debug=True)
bzrc = BZRC(host, int(port))

constants = bzrc.get_constants()

try:
    while True:
        mytanks, othertanks, flags, shots = bzrc.get_lots_o_stuff()
        enemies = [tank for tank in othertanks if tank.color != constants['team']]

        commands = []
        for bot in mytanks:
            best_enemy = None
            best_dist = 2 * float(constants['worldsize'])
            for enemy in enemies:
                if enemy.status != 'normal':
                    continue 
                dist = math.sqrt((enemy.x - bot.x)**2 + (enemy.y - bot.y)**2)
                if dist < best_dist:
                    best_dist = dist
                    best_enemy = enemy

            if best_enemy is None:
                command = Command(bot.index, 0, 0, False)
            else:
                target_angle = math.atan2(best_enemy.y - bot.y,
                        best_enemy.x - bot.x)
                relative_angle = normalize_angle(target_angle - bot.angle)
                command = Command(bot.index, 1, 2 * relative_angle, True)
            commands.append(command)

        results = bzrc.do_commands(commands)
        for bot, result in zip(mytanks, results):
            did_speed, did_angvel, did_shot = result
            if did_shot:
                print 'Shot fired by tank #%s (%s)' % (bot.index, bot.callsign)


except KeyboardInterrupt:
    print "Exiting due to keyboard interrupt."
    bzrc.close()


# vim: et sw=4 sts=4
