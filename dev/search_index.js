var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = Entities","category":"page"},{"location":"#Entities","page":"Home","title":"Entities","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for Entities.","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [Entities]","category":"page"},{"location":"#Entities.ComponentStorage","page":"Home","title":"Entities.ComponentStorage","text":"Contiguous storage of components keyed by entity.\n\nComponents may be used directly by systems without having to refer to individual entities, to avoid cache-unfriendly indirections caused by lookups.\n\nnote: Note\nComponent sharing among multiple entities is not yet supported. When a component is inserted for a new entity, and this component has been previously inserted for a different entity that is still present, then the component will be stored at another memory location. Component sharing can be achieved at the moment using a mutable component type, though performance will be severely degraded as mutable components will not be stored inline in memory (it is the pointers to such components which will be stored contiguously).\n\n\n\n\n\n","category":"type"}]
}
