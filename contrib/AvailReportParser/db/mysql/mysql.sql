SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL';

DROP SCHEMA IF EXISTS `reporting` ;
CREATE SCHEMA IF NOT EXISTS `reporting` DEFAULT CHARACTER SET latin1 ;
USE `reporting` ;

-- -----------------------------------------------------
-- Table `reporting`.`states`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `reporting`.`states` ;

CREATE  TABLE IF NOT EXISTS `reporting`.`states` (
  `id` INT NOT NULL ,
  `name` VARCHAR(45) NOT NULL ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `reporting`.`timetypes`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `reporting`.`timetypes` ;

CREATE  TABLE IF NOT EXISTS `reporting`.`timetypes` (
  `id` INT NOT NULL ,
  `name` VARCHAR(45) NOT NULL ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `reporting`.`reasontypes`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `reporting`.`reasontypes` ;

CREATE  TABLE IF NOT EXISTS `reporting`.`reasontypes` (
  `id` INT NOT NULL ,
  `name` VARCHAR(45) NOT NULL ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `reporting`.`reports`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `reporting`.`reports` ;

CREATE  TABLE IF NOT EXISTS `reporting`.`reports` (
  `id` INT NOT NULL AUTO_INCREMENT ,
  `date` DATETIME NOT NULL ,
  `hostname` VARCHAR(45) NOT NULL ,
  `service_description` VARCHAR(45) NULL ,
  `report_description` VARCHAR(255) NOT NULL ,
  `timeperiod` VARCHAR(45) NOT NULL ,
  `rpttimeperiod` VARCHAR(255) NULL ,
  `config_filename` VARCHAR(45) NOT NULL ,
  `execution_time` VARCHAR(45) NOT NULL ,
  `exit_status` TINYINT(4)  NOT NULL ,
  `message` VARCHAR(255) NOT NULL ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `reporting`.`raw_availability_breakdowns_percent`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `reporting`.`raw_availability_breakdowns_percent` ;

CREATE  TABLE IF NOT EXISTS `reporting`.`raw_availability_breakdowns_percent` (
  `id` INT NOT NULL AUTO_INCREMENT ,
  `report_id` INT NOT NULL ,
  `state_id` INT NOT NULL ,
  `reasontype_id` INT NOT NULL ,
  `timetype_id` INT NOT NULL ,
  `percent` VARCHAR(45) NOT NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `fk_availability_states1` (`state_id` ASC) ,
  INDEX `fk_availability_types1` (`timetype_id` ASC) ,
  INDEX `fk_availability_reasontypes1` (`reasontype_id` ASC) ,
  INDEX `fk_availability_reports1` (`report_id` ASC) ,
  CONSTRAINT `fk_availability_states1`
    FOREIGN KEY (`state_id` )
    REFERENCES `reporting`.`states` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_availability_types1`
    FOREIGN KEY (`timetype_id` )
    REFERENCES `reporting`.`timetypes` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_availability_reasontypes1`
    FOREIGN KEY (`reasontype_id` )
    REFERENCES `reporting`.`reasontypes` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_availability_reports1`
    FOREIGN KEY (`report_id` )
    REFERENCES `reporting`.`reports` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `reporting`.`raw_availability_breakdowns_time`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `reporting`.`raw_availability_breakdowns_time` ;

CREATE  TABLE IF NOT EXISTS `reporting`.`raw_availability_breakdowns_time` (
  `id` INT NOT NULL AUTO_INCREMENT ,
  `report_id` INT NOT NULL ,
  `state_id` INT NOT NULL ,
  `reasontype_id` INT NOT NULL ,
  `timetype_id` INT NOT NULL ,
  `days` INT NOT NULL ,
  `hours` INT NOT NULL ,
  `minutes` INT NOT NULL ,
  `seconds` INT(11)  NOT NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `fk_availability_states2` (`state_id` ASC) ,
  INDEX `fk_availability_types2` (`timetype_id` ASC) ,
  INDEX `fk_availability_reasontypes2` (`reasontype_id` ASC) ,
  INDEX `fk_availability_reports2` (`report_id` ASC) ,
  CONSTRAINT `fk_availability_states2`
    FOREIGN KEY (`state_id` )
    REFERENCES `reporting`.`states` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_availability_types2`
    FOREIGN KEY (`timetype_id` )
    REFERENCES `reporting`.`timetypes` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_availability_reasontypes2`
    FOREIGN KEY (`reasontype_id` )
    REFERENCES `reporting`.`reasontypes` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_availability_reports2`
    FOREIGN KEY (`report_id` )
    REFERENCES `reporting`.`reports` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `reporting`.`statetypes`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `reporting`.`statetypes` ;

CREATE  TABLE IF NOT EXISTS `reporting`.`statetypes` (
  `id` INT NOT NULL ,
  `name` VARCHAR(45) NOT NULL ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `reporting`.`objecttypes`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `reporting`.`objecttypes` ;

CREATE  TABLE IF NOT EXISTS `reporting`.`objecttypes` (
  `id` INT NOT NULL ,
  `name` VARCHAR(45) NOT NULL ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `reporting`.`raw_availability_logentries`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `reporting`.`raw_availability_logentries` ;

CREATE  TABLE IF NOT EXISTS `reporting`.`raw_availability_logentries` (
  `id` INT NOT NULL AUTO_INCREMENT ,
  `report_id` INT NOT NULL ,
  `start_time` DATETIME NOT NULL ,
  `stop_time` DATETIME NOT NULL ,
  `duration_days` INT NOT NULL ,
  `duration_hours` INT NOT NULL ,
  `duration_minutes` INT NOT NULL ,
  `duration_seconds` INT NOT NULL ,
  `event_text` VARCHAR(255) NOT NULL ,
  `objecttype_id` INT NOT NULL ,
  `state_id` INT NOT NULL ,
  `statetype_id` INT NOT NULL ,
  `state_information` VARCHAR(255) NOT NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `fk_raw_ng_availability_logentries_reports1` (`report_id` ASC) ,
  INDEX `fk_raw_ng_availability_logentries_states1` (`state_id` ASC) ,
  INDEX `fk_raw_ng_availability_logentries_statetypes1` (`statetype_id` ASC) ,
  INDEX `fk_raw_availability_logentries_objecttypes1` (`objecttype_id` ASC) ,
  CONSTRAINT `fk_raw_ng_availability_logentries_reports1`
    FOREIGN KEY (`report_id` )
    REFERENCES `reporting`.`reports` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_raw_ng_availability_logentries_states1`
    FOREIGN KEY (`state_id` )
    REFERENCES `reporting`.`states` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_raw_ng_availability_logentries_statetypes1`
    FOREIGN KEY (`statetype_id` )
    REFERENCES `reporting`.`statetypes` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_raw_availability_logentries_objecttypes1`
    FOREIGN KEY (`objecttype_id` )
    REFERENCES `reporting`.`objecttypes` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;



SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

-- -----------------------------------------------------
-- Data for table `reporting`.`states`
-- -----------------------------------------------------
START TRANSACTION;
USE `reporting`;
INSERT INTO `reporting`.`states` (`id`, `name`) VALUES (0, 'ok');
INSERT INTO `reporting`.`states` (`id`, `name`) VALUES (1, 'warning');
INSERT INTO `reporting`.`states` (`id`, `name`) VALUES (2, 'critical');
INSERT INTO `reporting`.`states` (`id`, `name`) VALUES (3, 'unknown');
INSERT INTO `reporting`.`states` (`id`, `name`) VALUES (4, 'undetermined');
INSERT INTO `reporting`.`states` (`id`, `name`) VALUES (5, 'all');
INSERT INTO `reporting`.`states` (`id`, `name`) VALUES (6, 'downtime');
INSERT INTO `reporting`.`states` (`id`, `name`) VALUES (7, 'up');
INSERT INTO `reporting`.`states` (`id`, `name`) VALUES (8, 'down');
INSERT INTO `reporting`.`states` (`id`, `name`) VALUES (9, 'unreachable');

COMMIT;

-- -----------------------------------------------------
-- Data for table `reporting`.`timetypes`
-- -----------------------------------------------------
START TRANSACTION;
USE `reporting`;
INSERT INTO `reporting`.`timetypes` (`id`, `name`) VALUES (0, 'time');
INSERT INTO `reporting`.`timetypes` (`id`, `name`) VALUES (1, 'knowntime');
INSERT INTO `reporting`.`timetypes` (`id`, `name`) VALUES (2, 'totaltime');

COMMIT;

-- -----------------------------------------------------
-- Data for table `reporting`.`reasontypes`
-- -----------------------------------------------------
START TRANSACTION;
USE `reporting`;
INSERT INTO `reporting`.`reasontypes` (`id`, `name`) VALUES (0, 'unscheduled');
INSERT INTO `reporting`.`reasontypes` (`id`, `name`) VALUES (1, 'scheduled');
INSERT INTO `reporting`.`reasontypes` (`id`, `name`) VALUES (2, 'total');
INSERT INTO `reporting`.`reasontypes` (`id`, `name`) VALUES (3, 'notrunning');
INSERT INTO `reporting`.`reasontypes` (`id`, `name`) VALUES (4, 'insufficientdata');

COMMIT;

-- -----------------------------------------------------
-- Data for table `reporting`.`statetypes`
-- -----------------------------------------------------
START TRANSACTION;
USE `reporting`;
INSERT INTO `reporting`.`statetypes` (`id`, `name`) VALUES (0, 'soft');
INSERT INTO `reporting`.`statetypes` (`id`, `name`) VALUES (1, 'hard');
INSERT INTO `reporting`.`statetypes` (`id`, `name`) VALUES (2, 'start');
INSERT INTO `reporting`.`statetypes` (`id`, `name`) VALUES (3, 'end');

COMMIT;

-- -----------------------------------------------------
-- Data for table `reporting`.`objecttypes`
-- -----------------------------------------------------
START TRANSACTION;
USE `reporting`;
INSERT INTO `reporting`.`objecttypes` (`id`, `name`) VALUES (1, 'host');
INSERT INTO `reporting`.`objecttypes` (`id`, `name`) VALUES (2, 'service');

COMMIT;
