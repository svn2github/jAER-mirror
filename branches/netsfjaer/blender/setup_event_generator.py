from distutils.core import setup, Extension
module = Extension('EventGenerator', sources=['camera_event_generator.c'])
setup(name = 'EventGenerator', version = '1.0', description = 'A module to generate jAER events.', ext_modules = [module])
