# Changelog

All notable changes to the ADExplorer to BloodHound Converter project will be documented in this file.

## [1.0.0] - 2024-10-03

### Added
- Initial project structure with PowerShell module framework
- ADExplorer .dat file header parsing functionality
- ADObject class for representing Active Directory objects
- BloodHoundOutput class for managing BloodHound JSON structure
- Object and attribute mapping from ADExplorer format
- BloodHound-compatible JSON output generation
- Support for Users, Computers, Groups, Domains, GPOs, OUs, and Containers
- Comprehensive documentation and examples
- Build script for packaging and distribution
- Test suite for basic functionality validation

### Features
- **Module Framework**: Complete PowerShell module with manifest and structure
- **Header Parsing**: ADExplorer .dat file format detection and header extraction
- **Object Mapping**: Conversion from ADExplorer objects to BloodHound format
- **Relationship Extraction**: Automatic detection of AD relationships
- **Flexible Output**: Configurable object filtering and output options
- **Error Handling**: Basic error handling and validation
- **Documentation**: Comprehensive README with usage examples
- **Testing**: Unit tests for core functionality

### Technical Details
- PowerShell 5.1+ compatible
- .NET Framework 4.7.2+ support
- BloodHound JSON v4 format compatibility
- Modular architecture for easy extension
- Comprehensive object property mapping

### Known Limitations
- Binary format parsing requires completion based on actual ADExplorer format
- SID parsing and resolution needs implementation
- ACL processing not yet implemented
- Performance optimization needed for large files
- Additional testing with real ADExplorer files required

### Development Status
- ✅ Project structure and framework
- ✅ Header parsing implementation
- ✅ Object and attribute mapping
- ✅ BloodHound JSON output
- 🚧 Binary format parsing (in progress)
- 🚧 SID resolution (pending)
- 🚧 ACL processing (pending)
- 🚧 Performance optimization (pending)
- 🚧 Comprehensive testing (pending)

### Next Steps
1. Complete binary format parsing implementation
2. Implement SID parsing and resolution
3. Add ACL processing capabilities
4. Optimize performance for large files
5. Add comprehensive test coverage
6. Validate with real ADExplorer files
