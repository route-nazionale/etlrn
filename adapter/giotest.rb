module Giotest
  class GiotestDatabase < ActiveRecord::Base
    self.abstract_class = true
    establish_connection CONFIG['db']['giotest']
  end

  class Riga < GiotestDatabase
    self.table_name = "TABLE"
    self.primary_keys = :IDX

  end

end