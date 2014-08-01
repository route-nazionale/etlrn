el_meno = ["AA-1471-026132","AA-1209-026075","AA-1214-024317","AA-0614-025564","AA-1010-025670","AA-0645-024346","AA-1423-025209","AA-1323-025654","AA-0931-027200","AA-1272-023132","AA-0971-026174","AA-1323-025653","AA-0931-027198","AA-0634-027478","AA-0999-026628","AA-0281-022924","AA-1419-026388","AA-0281-022926","AA-1423-025210","AA-0281-022928","OT-1541-028408"]


da vincoalre

vtav = ["AA-1483-023579","AA-0979-026758","AA-0748-024315","AA-0868-023939","AA-0314-025754","AA-1409-024680","AA-1483-023582","AA-1230-022848","AA-0311-027328","AA-1045-027108","AA-1460-022879","AA-0366-024440","AA-1520-025707","AA-0794-025651","AA-0864-025605","AA-0748-024314","AA-0314-025755","AA-1483-023580","AA-1259-024967","AA-1460-022877","AA-1470-024406","AA-0393-026669","AA-1315-023976","AA-1192-024502","AA-0314-025756"]

A::Abbspalla.where(cu: vtav).map{|i| i}


 cp = CSV.read("../capispallla/cpbk.csv", headers: true, col_sep: "\t")
cp.map{|i| A::Spalla.create(i.to_hash)}.size
el = el_meno.map{|i| A::Spalla.where(cu: i).first}
el.map{|i| i.try(:destroy)}

A::Spalla.where(lingue: "NULL").map{|i| i.lingue = nil; i.save}
A::Spalla.where(cu: vincolo_tav).map{|i| i.tipo = "TAV"; i.save}

el_new = ["701659","1101359","595865","1082470","742941","211668","546336","197748","640533","522092","1029902","506180","955391","691309","455759","1171181","558391","597066","1097754","1268230","896746","167281","1020080","1101772","371692","379563","1171194","691913","675816","146069","224052","379872","785138","788749","594023","23574","626288","648887","128484","504074","252956","648518","523003","1116062","27828","755134","375119","117636","1101133","181085","491203","1099416","800871","897170","865529","1024381","831605","573121","160155","774099","581589","734198","601497","31985","501446","666338","268753","907127","249949"]


Pry.config.editor = "nano"

# abbinamenti doppi

A::Abbspalla.select{|i| i.codice1 =~ /LAB/}.group_by { |e| e.codice1 }.select { |k, v| v.size > 1 }.map{|k,v| v}.flatten.map{|i| h = A::Human.where(cu: i.cu).first; l = Labcapi::Event.where(code: i.codice1).first; [i.cu, i.codice1,l.print_code, h.nome, h.cognome, h.codicecensimento].join("\t")}



lab_scoperti = A::Abbspalla.where(cu: vtav).pluck(:codice1).select{|i| i =~ /LAB/}


lab_coperti = (A::Abbspalla.pluck(:codice1).select{|i| i =~ /LAB/}.uniq - lab_scoperti)



 Labcapi::Assegncapo.where( event_happening_id: Event.where(state_activation: "DISMISSED").map{|i| i.turnos.pluck(:id)}.flatten).count


Event.where(id: Event.where(state_activation: "DISMISSED").map{|i| i.turnos}.flatten.select{|i| i.seats_n_chiefs > 0 or i.seats_n_boys > 0}.group_by{|i| i.event_id}.keys)

 el_code_eve = Event.where(state_activation: "ACTIVE").pluck(:code).select{|i| i =~ /LAB/}

spalle_libere = Spalla.all.select{|i| A::Abbspalla.where(cu: i.cu).count == 0}


el_code_eve = Event.where(state_activation: "ACTIVE").pluck(:code).select{|i| i =~ /LAB/}


["A","B","C","D","E","F"].map{|l| [Labcapi::Event.where("code like ?", "TAV-#{l}%").map{|i| i.turnos} ]}


ris = ["A","B","C","D","E","F"].map{|l| Labcapi::Event.where("code like ?", "TAV-#{l}%").map{|i| i.turnos}.flatten.group_by{|g| g.timeslot_id}}

triplette = ris.map{|r| [1,2,3].map{|k| [k, r[k].map{|i| Labcapi::Event.where(id: i.event_id).first.code}]}}.map{|l| [{1 => l[0][1][0], 2 => l[1][1][0], 3=> l[2][1][0]}, {1 => l[0][1][1], 2 => l[1][1][1], 3=> l[2][1][1]} ] }.flatten.select{| i| i[1]}.map{|i| i[:q] = i[1][4]; i}

capi_spalla_tav = A::Spalla.where(tipo: 'TAV').all
capi_spalla_tav_vincolati = capi_spalla_tav.select{|i| h =  A::Human.where(cu: i.cu).first; A::Tavola.pluck(:idgruppo).include? h.idgruppo}

#sistemazione capi spalla moderatori tavole
 capi_spalla_tav_vincolati.map{|s| abb = A::Abbspalla.where(cu: s.cu).first; h =  A::Human.where(cu: s.cu).first; t = A::Tavola.where(idgruppo: h.idgruppo).first; tr = triplette.select{|i| [i[1],i[2],i[3]].include? t.codice}.first; [abb, tr, h.quartiere] }.sort_by{|i| i[1][:q]}
 capi_spalla_tav_vincolati.map{|s| abb = A::Abbspalla.where(cu: s.cu).first; h =  A::Human.where(cu: s.cu).first; t = A::Tavola.where(idgruppo: h.idgruppo).first; tr = triplette.select{|i| [i[1],i[2],i[3]].include? t.codice}.first; abb.codice1 = tr[1]; abb.codice2 = tr[2]; abb.codice3 = tr[3]; abb.save; [abb, tr, h.quartiere] }.sort_by{|i| i[1][:q]}

#sistemazione altri capi spalla tavole
triplette.map{|tr|A::Abbspalla.where(codice1: tr[1]).count}
triplette.map{|tr| while((A::Abbspalla.where(codice1: tr[1]).count < 15) and (A::Abbspalla.where(cu: capi_spalla_tav.map{|i| i.cu}, codice1: '').count > 0))  do  n = A::Abbspalla.where(cu: capi_spalla_tav.map{|i| i.cu}, codice1: '').first; n.codice1 = tr[1]; n.codice2 = tr[2]; n.codice3 = tr[3]; n.save; puts n.cu end}




(laboratori = Labcapi::Event.where("code like ?", "LAB%").where(state_activation: "ACTIVE").all).size
(capi_spalla_lab = A::Spalla.where(tipo: 'LAB').all).size

el_lab = {}
rislab = ["A","B","C","D","E"].map{|l| el_lab[l] = Labcapi::Event.where("print_code like ?", "LAB-#{l}%").all}

abbinamenti_inutili = A::Abbspalla.where("codice1 like 'LAB%'").select{|l| !laboratori.pluck(:code).include?(l.codice1)}
codici_scoperti = (laboratori.pluck(:code) - A::Abbspalla.where("codice1 like 'LAB%'").pluck(:codice1) )

codici_scoperti.map{|c|  A::Abbspalla.where(codice1: "", cu: capi_spalla_lab.map{|i|i.cu} ).select{|p| ['A','B','C','D','E'][A::Human.where(cu: p.cu).first.quartiere] == c[4]}.size}


codici_scoperti.map do |c|
  abb = A::Abbspalla.where(codice1: "", cu: capi_spalla_lab.map{|i|i.cu} ).select{|p| ['A','B','C','D','E'][A::Human.where(cu: p.cu).first.quartiere] == c[4]}.first
  #abb = A::Abbspalla.where(codice1: "", cu: capi_spalla_lab.map{|i|i.cu} ).select{|p| A::Human.where(cu: p.cu).first.quartiere == 6}.first
  if abb
    abb.update_attributes(codice1: c, codice2: c, codice3: c)
  end
end

capi_spalla_senza_abbinamento = A::Spalla.all.select{|i| !A::Abbspalla.where(cu: i.cu).first}

capi_spalla_senza_abbinamento.map{|i| A::Abbspalla.where(cu: i.cu).first}.uniq
capi_spalla_senza_abbinamento.map{|i| A::Abbspalla.where(cu: i.cu).first_or_create(codice1: '',codice2: '',codice3: '',)}.size


A::Abbspalla.where(codice1: '').select{|i| A::Spalla.where(tipo: 'LAB', cu: i.cu).first}.size
A::Abbspalla.where(codice1: '').select{|i| A::Spalla.where(tipo: 'TAV', cu: i.cu).first}.map{|i| A::Human.where(cu: i.cu).first.quartiere}



# spalmatura tav su lab

codici_scoperti.map do |c|
  #abb = A::Abbspalla.where(codice1: "", cu: capi_spalla_tav.map{|i|i.cu} ).select{|p| ['A','B','C','D','E'][A::Human.where(cu: p.cu).first.quartiere] == c[4]}.first
  #abb = A::Abbspalla.where(codice1: "", cu: capi_spalla_lab.map{|i|i.cu} ).select{|p| ['1','2','3','4','5'][A::Human.where(cu: p.cu).first.quartiere] == c[4]}.first
  abb = A::Abbspalla.where(codice1: "", cu: capi_spalla_tav.map{|i|i.cu} ).select{|p| ['1','2','3','4','5'][A::Human.where(cu: p.cu).first.quartiere] == c[4]}.first
  #abb = A::Abbspalla.where(codice1: "", cu: capi_spalla_lab.map{|i|i.cu} ).select{|p| A::Human.where(cu: p.cu).first.quartiere == 6}.first
  if abb
    abb.update_attributes(codice1: c, codice2: c, codice3: c)
  end
end




mix = ["AA-0075-023646","AA-0084-024819","AA-0157-025025","AA-0270-023604","AA-0278-027293","AA-0513-024369","AA-0559-025983","AA-0754-026195","AA-0793-025322","AA-0809-023256","AA-0925-024477","AA-0986-023108","AA-1001-023478","AA-1199-026540","AA-1246-024465","AA-1367-026427","AA-1407-027318","AL-1514-028897","AL-1514-028900","OT-1541-027886","OT-1541-027979","OT-1541-028170","OT-1541-028315"]