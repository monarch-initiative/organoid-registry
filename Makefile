OBO=http://purl.obolibrary.org/obo/

all: organoid-kb.owl
test: all

organoid-kb.owl: organoid-ontology.obo curation.ttl
	owltools $^ --merge-support-ontologies -o $@

mirror/%.owl:
	wget --no-check-certificate $(OBO)/$*.owl -O $@

imports/%_import.owl: imports/mireot.txt
	robot extract -i mirror/$@.owl --method MIREOT --term-file $< -o $@

foo.owl:
	robot template -i mirror/uberon.owl 
