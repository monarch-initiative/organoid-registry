OBO=http://purl.obolibrary.org/obo/

organoid-kb.owl: organoid-ontology.obo curation.ttl
	owltools $^ --merge-support-ontologies -o $@

mirror/%.owl:
	wget --no-check-certificate $(OBO)/$*.owl -O $@

imports/%_import.owl: mireot.txt
	robot extract -i mirror/$@.owl --method MIREOT --term-file mireot.txt -o $@

foo.owl:
	robot -i mirror/uberon.owl 
