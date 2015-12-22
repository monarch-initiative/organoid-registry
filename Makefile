OBO=http://purl.obolibrary.org/obo/
MODS = organoid
ALL_MODS_OWL = $(patsubst %, modules/%.owl, $(MODS))
ROBOT=robot
USECAT= --use-catalog
KB= kb/organoid-instances.ttl

all: organoid-kb.owl organoid.owl organoid.ttl
test: all

organoid-kb.owl: organoid-core.obo $(KB) $(ALL_MODS_OWL)
	owltools $(USECAT) $^ --merge-support-ontologies -o $@

organoid.owl: organoid-kb.owl
	owltools $(USECAT) $< --assert-inferred-subclass-axioms -o $@
organoid.ttl: organoid.owl
	owltools $(USECAT) $< -o -f ttl $@

# ----------------------------------------
# ONTOLOGY CLASSES DERIVED BY PATTERNS
# ----------------------------------------

all_modules: all_modules_owl all_modules_obo 
all_modules_owl: $(ALL_MODS_OWL)
all_modules_obo: $(patsubst %, modules/%.obo, $(MODS))

modules/%.owl: modules/%.tsv patterns/%.yaml curie_map.yaml
	apply-pattern.py -P curie_map.yaml -b http://purl.obolibrary.org/obo/ -i $< -p patterns/$*.yaml  > modules/$*-orig.owl && owltools modules/$*-orig.owl --set-ontology-id $(OBO)/envo/modules/$*.owl -o $@

modules/%.obo: modules/%.owl
	owltools $(USECAT) $< -o -f obo $@.tmp && grep -v ^owl-axioms $@.tmp > $@

# ----------------------------------------
# IMPORT MODULE EXTRACTION
# ----------------------------------------

KEEPRELS = BFO:0000050 BFO:0000051 RO:0002202 immediate_transformation_of RO:0002176
mirror/%-orig.owl:
	wget --no-check-certificate $(OBO)/$*.owl -O $@
mirror/%.owl: mirror/%-orig.owl
	owltools $< --make-subset-by-properties -f $(KEEPRELS) // --remove-annotation-assertions -r -l -s -d --set-ontology-id $(OBO)/$*.owl -o $@





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

imports/mireot.txt: $(KB) $(ALL_MODS_OWL)
	owltools $^ --export-table -c $@.tmp && cut -f1 $@.tmp > $@
