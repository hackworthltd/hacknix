from setuptools import setup, find_packages

setup(
    name='trimpcap',
    version='1.3',
    packages=find_packages(),    
    install_requires=['dpkt', 'repoze.lru'],
)
