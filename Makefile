OBO=http://purl.obolibrary.org/obo/
MODS = organoid
ALL_MODS_OWL = $(patsubst %, modules/%.owl, $(MODS))
ROBOT=robot

all: organoid-kb.owl
test: all

organoid-kb.owl: organoid-core.obo curation.ttl $(ALL_MODS_OWL)
	owltools $^ --merge-support-ontologies -o $@

organoid.owl: organoid-kb.owl
	owltools --assert-inferred-subclass-axioms 

KEEPRELS = BFO:0000050 BFO:0000051 RO:0002202 immediate_transformation_of RO:0002176
mirror/%-orig.owl:
	wget --no-check-certificate $(OBO)/$*.owl -O $@
mirror/%.owl: %-orig.owl
	owltools $< --make-subset-by-properties -f $(KEEPRELS) // --remove-annotation-assertions -r -l -s -d --set-ontology-id $(OBO)/$*.owl -o $@





all_modules: all_modules_owl all_modules_obo 
all_modules_owl: $(ALL_MODS_OWL)
all_modules_obo: $(patsubst %, modules/%.obo, $(MODS))

modules/%.owl: modules/%.tsv patterns/%.yaml curie_map.yaml
	apply-pattern.py -P curie_map.yaml -b http://purl.obolibrary.org/obo/ -i $< -p patterns/$*.yaml  > modules/$*-orig.owl && owltools modules/$*-orig.owl --set-ontology-id $(OBO)/envo/modules/$*.owl -o $@

modules/%.obo: modules/%.owl
	owltools $< -o -f obo $@.tmp && grep -v ^owl-axioms $@.tmp > $@


IMPORTS = uberon
IMPORTS_OWL = $(patsubst %, imports/%_import.owl,$(IMPORTS)) $(patsubst %, imports/%_import.obo,$(IMPORTS))

# Make this target to regenerate ALL
all_imports: $(IMPORTS_OWL)

# Use ROBOT, driven entirely by terms lists NOT from source ontology
imports/%_import.owl: mirror/%.owl imports/mireot.txt
	$(ROBOT) extract -i $< -T imports/mireot.txt --method BOT -O $(SDG_IMPORTS_BASE_URI)/$@ -o $@
.PRECIOUS: imports/%_import.owl

imports/%_import.obo: imports/%_import.owl
	$(OWLTOOLS) $(USECAT) $< -o -f obo $@

imports/mireot.txt: curation.ttl $(ALL_MODS_OWL)
	owltools $^ --export-table -c $@.tmp && cut -f1 $@.tmp > $@
