module Camst
  class CamstDatabase < ActiveRecord::Base
    self.abstract_class = true
    establish_connection CONFIG['db']['camst']
  end

  # id  code  unit_id tipo_codice intolleranze_allergie std_meal  col     from_day  to_day  from_meal to_meal
  #  2  19824 1       scout       nessuna               standard  latte   5         10      0         2

  class Person < CamstDatabase
    self.table_name = "meal_provision_person"
  end

  # id  vclan   vclanID unitaID gruppoID  quartier_id storeroom_id  stock_id
  # 1   oneteam ONETEAM T1      onteam    6           26            551
  # 2   kinder  ASILO   T1      kinder    7           27            552

  class Vclan < CamstDatabase
    self.table_name = "meal_provision_unit"
  end

  class Quartier < CamstDatabase
    self.table_name = "meal_provision_quartier"
  end
end