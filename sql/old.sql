# 
#
# Database: cfgmaster
# ###########################
# version	0.1
# DBA: Dave Bradley
#

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `cfgmaster` /*!40100 DEFAULT CHARACTER SET latin1 */;

USE `cfgmaster`;

#
# Table structure for table `node`
# Nodes have a name and a description and are hierarchical.
# If there are multiple children of a category, a sequence field can
# be used to order the node for display.
# Tree nodes can be used to organize a network, data center, etc. 
#
DROP TABLE IF EXISTS `node`;
CREATE TABLE `node` (
	#Record creation time
	`created_on` datetime NOT NULL,

	#record ID
	`id` int(11) NOT NULL AUTO_INCREMENT,

	#Optional ID of image
	`imageid` int(11),

	#parent ID
	`parent_id` int(11) NOT NULL,

	#name
	`name` varchar(64) NOT NULL,

	#description 
	`description` varchar(128) NOT NULL,

	#sequence to display this node 
	`sequence` smallint(6) NOT NULL DEFAULT '0',

	PRIMARY KEY (`id`)
);

#
# Table structure for table `hosts`
# Hosts are computers that are managed by cfgmaster.
#
DROP TABLE IF EXISTS `hosts`;
CREATE TABLE `hosts` (
	#Record creation time
	`created_on` datetime NOT NULL,
 
	#record ID
	`id` int(11) NOT NULL AUTO_INCREMENT,

	#ID of optional image
	`imageid` int(11),

	#hostname or FQDN.  Should be DNS resolvable.
	`hostname` varchar(128) NOT NULL,

	#Architecture of this host
	`arch` enum('i386','i686','ppc','sparc'), 

	#OS of this host
	`os` enum('Linux','SunOS','Windows','Mac') default 'Linux', 

	# public key 
	`publickey` varchar(8192),

	PRIMARY KEY (`id`),
	UNIQUE KEY (`hostname`)
);

#
# Table structure for table `users`
# A user can be an individual, or a user can be a group.   A group can
# contain 0 or more users.  `groupmembers` define what users belong to a group.
# A user (or group) can login via our system, or via Facebook, or via Google.
#
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
	#Record creation time
	`created_on` datetime NOT NULL,
 
	#ID of user 
	`id` int(11) NOT NULL AUTO_INCREMENT,

	#
	# Name by which users will see this user on the app - must be set.
	# If the user is using their Facebook, Twitter, or Google account
	# to login, this will be set to that username. 
	#
	`username` varchar(64) NOT NULL,

	#Email address - must be set
	`email` varchar(128) NOT NULL,

	#Password, if account is local
	`password` varchar(128) DEFAULT NULL,

	#Time of last login, or NULL if never logged in
	`last_login` datetime DEFAULT NULL,

	#Record registration time
	`registered_on` datetime,

	#Registration code - entered through email sent after online registration.
	`registercode` int(11) DEFAULT '0',

	#Is this user actually a group?  e.g. a club or something.
	`isgroup` enum('N','Y') DEFAULT 'N',

	#ID of optional avatar image
	`imageid` int(11),

	PRIMARY KEY (`id`),

	UNIQUE KEY `username` (`username`),
	UNIQUE KEY `email` (`email`)
);

#
# Table structure for table `groupmembers`
#
DROP TABLE IF EXISTS `groupmembers`;
CREATE TABLE `groupmembers` (
	#Record creation time
	`created_on` datetime NOT NULL,

	#ID of group (users table entry with isgroup=='Y') 
	`groupid` int(11) NOT NULL,

	#ID of user who is a member of this group. 
	`userid` int(11) NOT NULL,

	 UNIQUE KEY (`groupid`,`userid`)
);

#
# Table structure for `meta`
# A way to associate key-value pairs.  This metadata can be
# assigned to hosts, groups, or anything.
# 
DROP TABLE IF EXISTS `meta`;
CREATE TABLE `meta` (
	#Record creation time
	`created_on` datetime NOT NULL,

	#ID  
	`id` int(11) NOT NULL,

	#Key - Defined by application
	`keystr` varchar(128) NOT NULL,

	#Value - optional value for the key
	`valstr` varchar(128),

	#Optional image ID.
	`imageid` int(11),

	PRIMARY KEY (`id`)
);


#
# Table structure for `images`
#
DROP TABLE IF EXISTS `images`;
CREATE TABLE `images` (
	#Record creation time
	`created_on` datetime NOT NULL,

	#ID of image 
	`id` int(11) NOT NULL AUTO_INCREMENT,

	#Optional text associated with image
	`text` varchar(128) DEFAULT NULL,

	#Optional URL associated with image
	`url` varchar(255) DEFAULT NULL,

	#Image binary data
	`image` mediumblob NOT NULL,

	#Image width
	`image_width` int(11) DEFAULT NULL,

	#Image height 
	`image_height` int(11) DEFAULT NULL,

	#Format of image
	`format` enum('jpg','png','gif') NOT NULL,

	#Type of image
	`type` enum('LOGO','MENU','PHOTO','AVATAR','QRCODE') DEFAULT NULL,

	PRIMARY KEY (`id`)
);
