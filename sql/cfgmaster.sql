#
# Create the database.
#
create database if not exists cfgmaster;
use cfgmaster;

#
# Create the 'users' table.
#
DROP TABLE IF EXISTS `users`;
CREATE TABLE if not exists users (
	#
	# Timestamp of the insert or last modification of this record.
	#
	timestamp DATETIME,

	#record ID
	`id` INT NOT NULL AUTO_INCREMENT,

	#Optional ID of image
	`imageid` INT,

	username VARCHAR(128) NOT NULL,
	password VARCHAR(128),
	PRIMARY KEY (id,username),
	INDEX (username)
);

#
# Create the 'groups' table.
#
DROP TABLE IF EXISTS `groups`;
CREATE TABLE if not exists groups (
	#
	# Timestamp of the insert or last modification of this record.
	#
	timestamp DATETIME,

	#record ID
	`id` INT NOT NULL AUTO_INCREMENT,

	#Optional ID of image
	`imageid` INT,

	groupname VARCHAR(128) NOT NULL,
	PRIMARY KEY (id,groupname),
	INDEX (groupname)
);


#
# Create the 'user_to_groups' table.
#
DROP TABLE IF EXISTS `user_to_groups`;
CREATE TABLE if not exists user_to_groups (
	#
	# Timestamp of the insert or last modification of this record.
	#
	timestamp DATETIME,

	#user ID
	`user_id` INT NOT NULL,

	#group ID
	`group_id` INT NOT NULL,

	PRIMARY KEY (user_id,group_id)
);


#
# Create the 'trait' table.
# A 'trait' is a group of content and metadata that describes a particular
# trait that servers below inherit.    An example of this would be a trait
# called 'London Datacenter'.    All content specific to the London datacenter
# would be attached to this trait.   Hosts in the London datacenter would
# directly inherit from this trait.   The content in here might include a
# London-specific ntp.conf, resolv.conf, and sendmail.cf.   
#
DROP TABLE IF EXISTS `trait`;
CREATE TABLE if not exists trait
(
	#
	# Timestamp of the insert or last modification of this record.
	#
	timestamp DATETIME,

	#record ID
	`id` INT NOT NULL AUTO_INCREMENT,

	#Optional ID of image
	`imageid` INT,

	#
	# Trait name (e.g. 'basic solaris2.8 220R' or 'M-Complex' or 'nba4')
	# This does not have to be unique.
	#
	name VARCHAR(128) NOT NULL,

	#
	# Are we in read-only mode?  If so no changes will
	# occur in this trait or any of its children.
	#
	readonly ENUM('N','Y') NOT NULL DEFAULT 'N',

	#
	# Optional location ID.
	#
	location_id INT UNSIGNED,

	#
	# Optional OS ID
	#
	os_id INT UNSIGNED,

	#
	# Optional Architecture ID.
	#
	arch_id INT UNSIGNED,

	PRIMARY KEY(id),
	UNIQUE INDEX (name)
);

#
# Create the 'trait_topology' table.
# This defines the relationship of traits to each other.
# It allows for multiple parenting.   This is not necessarily a
# tree structure, although a tree structure can be created.   The likely
# configuration will be several individual traits, with no topology, and
# maybe a few with parents.
#
DROP TABLE IF EXISTS `trait_topology`;
CREATE TABLE if not exists trait_topology
(
	#
	# Timestamp of the insert or last modification of this record.
	#
	timestamp DATETIME,

	#
	# Trait ID
	#
	trait_id INT UNSIGNED NOT NULL,

	#
	# Parent trait ID
	#
	parent_trait_id INT UNSIGNED NOT NULL,

	PRIMARY KEY(trait_id,parent_trait_id)
);

#
# Create the 'metadata' table.
# This table is used to store anything that is used
# to aid in the deployment of traits or hosts at a customer site.
# e.g. There may be graphics embedded in here to display 
# on an advanced user interface.  Or it could be used to
# contain names and phone numbers of people responsible for
# administering the trait if used over a wide-area-network.
# whatever...
#
DROP TABLE IF EXISTS `metadata`;
CREATE TABLE if not exists metadata
(
	#
	# Timestamp of the insert or last modification of this record.
	#
	timestamp DATETIME,

	#
	# Metadata ID
	#
	id INT UNSIGNED NOT NULL,

	#
	# key (e.g. 'architecture')
	#
	metakey VARCHAR(255) NOT NULL,

	#
	# value (e.g. 'sparc') 
	#
	metaval TEXT,

	PRIMARY KEY (id),
	INDEX (metakey)
);

#
# Trait to metadata mapping.
#
DROP TABLE IF EXISTS `trait_to_meta`;
CREATE TABLE if not exists trait_to_meta
(
	#
	# Timestamp of the insert or last modification of this record.
	#
	timestamp DATETIME,

	#
	# Trait ID
	#
	trait_id INT UNSIGNED NOT NULL,

	#
	# Metadata ID
	#
	metadata_id INT UNSIGNED NOT NULL,

	PRIMARY KEY (trait_id,metadata_id)
);

#
# Host to metadata mapping.
#
DROP TABLE IF EXISTS `host_to_meta`;
CREATE TABLE if not exists host_to_meta
(
	#
	# Timestamp of the insert or last modification of this record.
	#
	timestamp DATETIME,

	#
	# Host ID
	#
	host_id INT UNSIGNED NOT NULL,

	#
	# Metadata ID
	#
	metadata_id INT UNSIGNED NOT NULL,

	PRIMARY KEY (host_id,metadata_id)
);

#
# Create the 'trait_acl' table.
# This maintains the user access control lists for each trait.    By default
# the ACLs are inherited by the child traits of a particular trait.
# If the 'noinherit' flag is set, then this is not the case.
#
DROP TABLE IF EXISTS `trait_acl`;
CREATE TABLE if not exists trait_acl
(
	#
	# Timestamp of the insert or last modification of this record.
	#
	timestamp DATETIME,

	#
	# Class ID
	#
	trait_id INT UNSIGNED NOT NULL,

	#
	# Username or Groupname 
	#
	name VARCHAR(50) NOT NULL,

	#
	# Is this a groupname?  If not, then its a username.
	#
	is_groupname ENUM('N','Y') NOT NULL DEFAULT 'N',

	#
	# Are they allowed to read? 
	#
	can_read_topology ENUM('N','Y') NOT NULL DEFAULT 'Y',

	#
	# Are they allowed to modify topology? 
	#
	can_modify_topology ENUM('N','Y') NOT NULL DEFAULT 'N',

	#
	# Are they allowed to read content? 
	#
	can_read_content ENUM('N','Y') NOT NULL DEFAULT 'Y',

	#
	# Are they allowed to modify content? 
	#
	can_modify_content ENUM('N','Y') NOT NULL DEFAULT 'N',

	#
	# Are they allowed to execute changes on hosts?
	#
	can_execute ENUM('N','Y') NOT NULL DEFAULT 'N',

	PRIMARY KEY (trait_id,name)
);

#
# Table structure for table `hosts`
# Hosts are computers that are managed by cfgmaster.
#
# Hosts can be attached to multiple traits in the hierarchy.
# The host will inherit properties from its trait parents.  This
# can lead to loops and other problems.   For instance, if a host
# is parented by a trait that says it's in one datacenter and another
# trait that says it's in another datacenter, then we have an impossible
# situation.  We need a way to limit certain properties to a single
# instance.  i.e. a host (or trait) cannot inherit, or set, multiple
# locations.
# One way to solve this problem is to have metadata types that are 
# pervasive.   i.e. If a trait has a physical location associated with
# it, then no child trait (or host) may override this.   A physical
# location is a physical location.   The location can be enhanced, but
# not replaced.  i.e. We may have a trait called 'London' which sets a
# country of 'England' and a city of 'London'.   No trait (or host) beneath
# it may redefine country or city.   But a trait underneath could set
# an address.   We may further define location to a data center name, floor,
# room, row, and rack.   
#
DROP TABLE IF EXISTS `hosts`;
CREATE TABLE `hosts` (
	#
	# Timestamp of the insert or last modification of this record.
	#
	timestamp DATETIME,
 
	#record ID
	`id` INT NOT NULL AUTO_INCREMENT,

	#ID of optional image
	`imageid` INT,

	#hostname or FQDN.  Should be DNS resolvable.
	`hostname` varchar(128) NOT NULL,

	# public key unique to this host.
	`publickey` varchar(8192),

	PRIMARY KEY (`id`)
);

#
# Table structure for table `host_topology`.  What trait(s)
# is this host attached to?
#
DROP TABLE IF EXISTS `host_topology`;
CREATE TABLE `host_topology` (
	#
	# Timestamp of the insert or last modification of this record.
	#
	timestamp DATETIME,
 
	#host ID
	`host_id` INT NOT NULL,

	#trait ID
	`trait_id` INT NOT NULL,

	PRIMARY KEY (`host_id`,`trait_id`)
);

#
# Create the 'resource' table.
# A resource is a file, directory, package,
# archive, symbolic link, script to run, etc.
# (a thing that needs to be managed).
#
DROP TABLE IF EXISTS `resource`;
create table if not exists resource
(
	#
	# Timestamp of the insert or last modification of this record.
	#
	timestamp DATETIME,

	#record ID
	`id` INT NOT NULL AUTO_INCREMENT,

	#ID of optional image
	`imageid` INT,


	#
	# Where did this come from.  This URL describes the
	# protocol, host, and path of this place the content
	# for this resource came from.
	# e.g.
	# nfs:/csjump.prod.nyfix.com/pkgs/pkgs/nyfixha/current
	# file://export/depot/packages/foo/foo.dstream
	# ftp://nbjump.prod.nyfix.com/export/depot/packages/bar/bar.rpm
	# http://www.redhat.com/rhn/foobar/foobar.rpm
	#
	url VARCHAR(255),

	#
	# Where does this get installed on the remote host?
	#
	remote_path VARCHAR(255) NOT NULL,
		INDEX (remote_path),
#		UNIQUE INDEX (remote_path,checksum,fileowner,filegroup,filemode),

	#
	# What is the name of this resource?
	# It is really meant for records of type PKG
	# or PATCH to represent their logical name (e.g.
	# 110938-04 or SUNWcsu). Resources of type LINK
	# use this to store the target of the link. 
	#
	name VARCHAR(255),

	#
	# Description.
	#
	description VARCHAR(255),

	#
	# What type of resource is this?  We may add more
	# here but the idea is to give a hint to the remote
	# agent on how to treat this resource.  Also, the
	# remote agent may want to see "all packages" or "all files".
	# A query of that type is possible.
	#
	type ENUM('FILE','DIR','LINK','PKG','SCRIPT','PATCH','ARCHIVE') NOT NULL DEFAULT 'FILE',
		INDEX (type),

#	subtype ENUM('PKG_SOLARIS','PKG_SOLARIS_DSTREAM','PKG_SOLARIS_EMBEDDED','PKG_RPM','PKG_DPKG','PKG_SLP','PKG_TGZ','PKG_ZIP','ARC_ZIP','ARC_CPIO','ARC_TAR') NOT NULL,

	#
	# The MIME type of the resource.  If the resource is
	# compressed, this MIME type will describe the compression type
	# and you'll have to refer to the submime type to determine what's
	# underneath.
	#
	mime VARCHAR(64),

	#
	# The SUB-MIME type.
	# This will most likely be set only if this resource is compressed.
	# In this case submime will be set to the MIME type of the uncompressed
	# resource.
	#
	submime VARCHAR(64),

	#
	# If the resource should not exist on the remote server,
	# then this field is set to 'Y'.
	#
	must_not_exist ENUM('N','Y') NOT NULL DEFAULT 'N',
		INDEX (must_not_exist),

	#
	# The owner of the resource.  This is treated somewhat
	# differently depending on the operating system that
	# this resource belongs to.
	# This can be NULL if 'must_not_exist' is 'Y'.
	#
	fileowner VARCHAR(32) NOT NULL,

	#
	# The group of the resource.  This is treated somewhat
	# differently depending on the operating system that
	# this resource belongs to.
	# This can be NULL if 'must_not_exist' is 'Y'.
	#
	filegroup VARCHAR(32) NOT NULL,

	#
	# The mode of the resource.  This is treated somewhat
	# differently depending on the operating system that
	# this resource belongs to.
	# This gets used for other purposes as well.  In the
	# case of packages, it contains the type of package.
	#
	filemode VARCHAR(32) NOT NULL,

	#
	# The size of the file.
	#
	filesize INT(64),

	#
	# The modification date and time.
	#
	mtime DATETIME,

	#
	# The checksum of the resource.
	# This can be NULL if 'must_not_exist' is 'Y'.
	#
	checksum VARCHAR(64) NOT NULL,

	#
	# Resource version.  This might represent the
	# version number of a package.  It is resource-dependent.
	#
	version VARCHAR(64),

	#
	# RCS version number.
	#
	rcsversion VARCHAR(8),

	#
	# This is a sequence number that can be used to set 
	# the order of which resources get installed. 
	#
	install_sequence INT UNSIGNED,

	PRIMARY KEY (`id`)
);

#
# Create the 'resource_topology' table.
# This defines parent-child relationships between
# resources.  It is used primarily for grouping resources
# together into 'meta-clusters'.  A meta-cluster is an
# on-the-fly clustering of resources to make it easier
# to manage them.  A good example of this would be a set
# of patches that makes up a "recommended" set.  You could
# create one parent resource called 'recommended_patches'
# that would be shell under which several real patch resources
# would belong.  Then you could just say 'install recommended_patches'.
#
DROP TABLE IF EXISTS `resource_topology`;
CREATE TABLE if not exists resource_topology
(
	#
	# Timestamp of the insert or last modification of this record.
	#
	timestamp DATETIME,
 
	#
	# Class ID
	#
	resource_id INT UNSIGNED NOT NULL,

	#
	# Resource ID
	#
	child_resource_id INT UNSIGNED NOT NULL,

	PRIMARY KEY (resource_id,child_resource_id)
);

#
# Create the 'trait_to_resource' table.
# This assigns a resource to a trait.
# This allows a resource to exist in multiple traits. 
#
DROP TABLE IF EXISTS `trait_to_resource`;
CREATE TABLE if not exists trait_to_resource
(
	#
	# Timestamp of the insert or last modification of this record.
	#
	timestamp DATETIME,

	#
	# Class ID
	#
	trait_id INT UNSIGNED NOT NULL,
		PRIMARY KEY (trait_id,resource_id),

	#
	# Resource ID
	#
	resource_id INT UNSIGNED NOT NULL,

	remote_path VARCHAR(255) NOT NULL
);

#
# Create the 'resource_exception' table.
# This table is used to tell Redeye to "ignore" a particular
# resource for a given trait.  It is also possible to ignore
# the resource for all traits by leaving the trait_id 0.
# This might be useful if one wanted to temporarily prevent
# the rollout of a resource.
#
DROP TABLE IF EXISTS `resource_exception`;
CREATE TABLE if not exists resource_exception
(
	#
	# Timestamp of the insert or last modification of this record.
	#
	timestamp DATETIME,

	#
	# Class ID of imposing trait or 0 if it applies
	# to all inheriting traits of this resource.
	#
	trait_id INT UNSIGNED NOT NULL,
		PRIMARY KEY (trait_id,resource_id),

	#
	# Resource ID
	#
	resource_id INT UNSIGNED NOT NULL
);

#
# Create the 'resource_metadata' table.
#
DROP TABLE IF EXISTS `resource_metadata`;
CREATE TABLE if not exists resource_metadata
(
	#
	# Timestamp of the insert or last modification of this record.
	#
	timestamp DATETIME,

	#
	# Resource ID
	#
	resource_id INT UNSIGNED NOT NULL,

	#
	# key
	#
	metakey VARCHAR(255) NOT NULL,
		INDEX (metakey),

	#
	# value
	#
	metaval TEXT,

	PRIMARY KEY (resource_id,metakey)
);

#
# Create the 'mime_metadata' table.  This contains
# resource options that affect the operation
# of the packaging or archive infrastructure at the global level.
# This is keyed by MIME type.
#
# For example, if you have RPM-based systems and you never
# care about dependencies when installing packages, you
# can tell RPM that here.
#
# Another example is to install the Solaris package admin file
# as an entry in here.
#
DROP TABLE IF EXISTS `mime_metadata`;
create table if not exists mime_metadata
(
	#
	# Timestamp of the insert or last modification of this record.
	#
	timestamp DATETIME,

	mime VARCHAR(64) NOT NULL,
		PRIMARY KEY (mime,metakey),
	#
	# key
	#
	metakey VARCHAR(255) NOT NULL,
		INDEX (metakey),

	#
	# value
	#
	metaval TEXT

);

#
# Table structure for table `locations`.  
#
DROP TABLE IF EXISTS `locations`;
CREATE TABLE `locations` (
	#
	# Timestamp of the insert or last modification of this record.
	#
	timestamp DATETIME,
 
	#ID
	`id` INT NOT NULL,

	country VARCHAR(128),
	city VARCHAR(128),
	address VARCHAR(128),
	building VARCHAR(128),
	floor VARCHAR(128),
	row VARCHAR(128),
	rack VARCHAR(128),

	PRIMARY KEY (`id`)
);

#
# Table structure for table `operating_systems`.  
#
DROP TABLE IF EXISTS `operating_systems`;
CREATE TABLE `operating_systems` (
	#
	# Timestamp of the insert or last modification of this record.
	#
	timestamp DATETIME,
 
	#ID
	`id` INT NOT NULL,

	os VARCHAR(64),
	version VARCHAR(64),
	patch VARCHAR(64),

	PRIMARY KEY (`id`)
);

#
# Table structure for table `architectures`.  
#
DROP TABLE IF EXISTS `architectures`;
CREATE TABLE `architectures` (
	#
	# Timestamp of the insert or last modification of this record.
	#
	timestamp DATETIME,
 
	#ID
	`id` INT NOT NULL,

	os VARCHAR(64),
	version VARCHAR(64),
	patch VARCHAR(64),

	PRIMARY KEY (`id`)
);


#
# Create the 'helper' table.
# These are things needed to help install/remove/check
# resources.
#
DROP TABLE IF EXISTS `helper`;
CREATE TABLE if not exists helper
(
	#
	# Timestamp of the insert or last modification of this record.
	#
	timestamp DATETIME,

	#
	# Name.
	#
	name VARCHAR(64) NOT NULL,
		PRIMARY KEY (name,type),

	#
	# Description.
	#
	description VARCHAR(255),

	#
	# If this is a script, run as this user and group.
	#
	runas_user VARCHAR(32),

	runas_group VARCHAR(32),

	
	#
	# Type of helper.  Helpers are available to
	# help in installing, removing, or checking
	# a resource on a system.  A helper can be
	# a script, or just text.
	#
	# THERE CAN BE ONLY ONE OF EACH KIND OF HELPER
	# FOR ANY GIVEN RESOURCE.
	#
	# INSTALL_RESPONSE_TEXT	- Text for responses for installation queries.
	# REMOVE_RESPONSE_TEXT	- Text for responses for removal queries
	# INSTALL_RESPONSE_SCRIPT	- Script that generates responses for installation queries. 
	# REMOVE_RESPONSE_SCRIPT	- Script that generates responses for removal queries. 
	# SOLARIS_RESPONSE_TEXT	- A Solaris package response file
	# PREINSTALL_SCRIPT	- A script to run before installation
	# POSTINSTALL_SCRIPT	- A script to run after installation
	# PREREMOVE_SCRIPT	- A script to run before removal 
	# POSTREMOVE_SCRIPT	- A script to run after removal
	# CHECK_SCRIPT		- A script to run during the check phase
	#
	type ENUM('INSTALL_RESPONSE_TEXT','REMOVE_RESPONSE_TEXT','INSTALL_RESPONSE_SCRIPT','REMOVE_RESPONSE_SCRIPT','SOLARIS_RESPONSE_TEXT','PREINSTALL_SCRIPT','POSTINSTALL_SCRIPT','PREREMOVE_SCRIPT','POSTREMOVE_SCRIPT','CHECK_SCRIPT') NOT NULL, 

	#
	# This contains the actual helper script code, or text.
	#
	value MEDIUMTEXT
);

#
# Mapping between an individual resource and helpers
# that belong to it.
#
CREATE TABLE if not exists resource_to_helper
(
	#
	# Timestamp of the insert or last modification of this record.
	#
	timestamp DATETIME,

	resource_id INT UNSIGNED NOT NULL,
		PRIMARY KEY (resource_id,helper_name),
	helper_name VARCHAR(64) NOT NULL 
);

#
# Mapping between a trait and helpers
# that belong to it.  These are helpers that
# will be used, by default, if no resource-specific
# helpers are found.
#
CREATE TABLE if not exists trait_to_helper
(
	#
	# Timestamp of the insert or last modification of this record.
	#
	timestamp DATETIME,

	trait_id INT UNSIGNED NOT NULL,
		PRIMARY KEY (trait_id,helper_name),
	helper_name VARCHAR(64) NOT NULL 
);

#
# Create the 'log' table.
# This maintains a list of log messages generated by
# the tools that use this database.  It is supposed to
# keep an audit trail of events on systems.  Those events
# include:
#	1) system installation
#	2) system modification
#	3) check failure
#	4) check successful
CREATE TABLE if not exists log
(
	#
	# When did it happen?  This gets automatically set when
	# a record is inserted.
	#
	stamp DATETIME NOT NULL,

	#
	# Log ID
	#
	log_id INT UNSIGNED NOT NULL auto_increment,
		PRIMARY KEY (log_id),
		UNIQUE INDEX (log_id),

	#
	# Username of user who instigated (if a user instigated).
	#
	username CHAR(50),

	#
	# Class ID
	# Where did it happen? (e.g. What host or complex?)
	#
	trait_id INT UNSIGNED,

	#
	# Resource ID
	# What resource, if any, was involved?
	#
	resource_id INT UNSIGNED,

	#
	# event
	#
	event ENUM('INSTALL','REMOVE','MODIFY','CHECK','FIXME') NOT NULL,

	#
	# level
	#
	level ENUM('INFO','WARNING','ERROR') NOT NULL,

	#
	# The actual log message. This can be empty.
	# In the case of 'FIXME' messages, this will contain
	# a string detailing exactly what's wrong with the given
	# resource (e.g. package version out-of-date,file checksum,missing link,etc.).
	#
	msg VARCHAR(255)
);

#
# Create the user 'cfgmaster' with minimal privileges.
#
grant select,delete,insert,update on * to cfgmaster@localhost identified by '2bornot2b';
grant select,delete,insert,update on * to cfgmaster identified by '2bornot2b';

#
# Insert some basic stuff.
#
INSERT INTO mime_metadata (mime,metakey,metaval) VALUES('application/x-rpm','BINARY','/bin/rpm');
INSERT INTO mime_metadata (mime,metakey,metaval) VALUES('application/x-rpm','INSTALL_ARGS','--upgrade');
INSERT INTO mime_metadata (mime,metakey,metaval) VALUES('application/x-rpm','REMOVE_ARGS','--erase --traitps');
INSERT INTO mime_metadata (mime,metakey,metaval) VALUES('application/x-archiveapplication-x-debian-package','BINARY','/bin/dpkg');
INSERT INTO mime_metadata (mime,metakey,metaval) VALUES('application/x-archiveapplication-x-debian-package','INSTALL_ARGS','--install');
INSERT INTO mime_metadata (mime,metakey,metaval) VALUES('application/x-archiveapplication-x-debian-package','REMOVE_ARGS','--remove');
INSERT INTO mime_metadata (mime,metakey,metaval) VALUES('application/x-svr4-package','PKGADD','/usr/sbin/pkgadd');
INSERT INTO mime_metadata (mime,metakey,metaval) VALUES('application/x-svr4-package','PKGRM','/usr/sbin/pkgrm');
INSERT INTO mime_metadata (mime,metakey,metaval) VALUES('application/x-svr4-package','INSTALL_ARGS','');
INSERT INTO mime_metadata (mime,metakey,metaval) VALUES('application/x-svr4-package','REMOVE_ARGS','-n');
INSERT INTO mime_metadata (mime,metakey,metaval) VALUES('application/x-svr4-package','ADMIN','mail=root\ninstance=unique\npartial=nocheck\nrunlevel=nocheck\nidepend=nocheck\nrdepend=nocheck\nspace=nocheck\nsetuid=nocheck\nconflict=nocheck\naction=nocheck\nbasedir=default\n');
INSERT INTO users(username,password) VALUES('admin',MD5('change_me'));
#INSERT INTO trait (trait_id,name,traitkey,is_trait,readonly) VALUES(1,'_cfgmaster_root_','','N','N');
