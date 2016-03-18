define check_relation
 psql -d $(PG_DB) -c "\d $@" > /dev/null 2>&1 ||
endef

PG_DB=deep

db :
	createdb deep

regular_nonprofits.csv : All\ Chicago\ Nonprofits\ For\ Forest\ Gregg.xlsx 
	in2csv --sheet chicago_nonprofits_regular.csv "$<" > $@


regular_nonprofits : regular_nonprofits.csv
	$(check_relation) csvsql --db postgresql:///$(PG_DB) --insert $<

top_nonprofits.csv : regular_nonprofits
	psql -d $(PG_DB) -c "copy (select primary_name_of_organization, \
                                          totrevenue, \
                                          ein \
                                   from (select distinct on (ein) * \
                                         from $< \
                                         order by ein, tax_pd desc) distinct_ein \
                                   where subseccd not in (9,5,25,14) \
                                         and operatehosptlcd=False \
                                   order by totrevenue desc \
                                   limit 100) \
                             to stdout \
                             with csv header" > $@
