from aether.mocker import MockingManager, MockFn, Generic

def main():
    SEED_ENTITIES = 1000
    entities = []
    manager = None
    survey = "eha.aether.clusterdemo.Survey"
    building = "eha.aether.clusterdemo.Building"
    household = "eha.aether.clusterdemo.HouseHold"
    person = "eha.aether.clusterdemo.Person"

    manager = MockingManager(kernel_url='http://localhost:8000')
    for i in manager.types.keys():
        print(i)
    for k,v in manager.names.items():
        print(k,v)
    manager.types[building].override_property(
        "latitude", MockFn(Generic.geo_lat))
    manager.types[building].override_property(
        "longitude", MockFn(Generic.geo_lng))
    for x in range(SEED_ENTITIES):
        entity = manager.register(person)

if __name__ == "__main__":
    main()
