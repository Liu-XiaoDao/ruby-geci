CREATE TABLE IF NOT EXISTS `lyc`(
   `id` INT UNSIGNED AUTO_INCREMENT,
   `lycname` VARCHAR(100),
   `album` VARCHAR(40),
   `albumLink` VARCHAR(100),
   `artist` VARCHAR(100),
   `artistLink` VARCHAR(100),
   `lyccontent` text,
   PRIMARY KEY ( `runoob_id` )
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `lyc`(`id` INT UNSIGNED AUTO_INCREMENT, `lycname` VARCHAR(100), `album` VARCHAR(40), `albumLink` VARCHAR(100), `artist` VARCHAR(100), `artistLink` VARCHAR(1000),`lyccontent` text, PRIMARY KEY (`id`))ENGINE=InnoDB DEFAULT CHARSET=utf8;
