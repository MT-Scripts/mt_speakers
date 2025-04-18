CREATE TABLE `speakers` (
	`id` INT(11) NOT NULL AUTO_INCREMENT,
	`item` VARCHAR(50) NULL DEFAULT NULL,
	`location` LONGTEXT NULL DEFAULT '[]',
	`users` LONGTEXT NULL DEFAULT '[]',
	`owner` VARCHAR(50) NULL DEFAULT NULL,
	PRIMARY KEY (`id`) USING BTREE
);

CREATE TABLE `speakers_musics` (
	`musicId` INT(11) NOT NULL AUTO_INCREMENT,
	`citizenid` VARCHAR(50) NOT NULL,
	`label` LONGTEXT NOT NULL,
	`url` LONGTEXT NOT NULL,
	PRIMARY KEY (`musicId`) USING BTREE
);
