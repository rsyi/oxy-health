// Cube.js configuration file
// This file defines data source configurations for query generation
// Since we're not executing with CubeJS, this just provides the database types

module.exports = {
  dbType: ({ securityContext, dataSource }) => {
    if (dataSource === "motherduck") return "duckdb";

    return 'duckdb'; // default
  },
  driverFactory: ({ securityContext, dataSource }) => {
    if (dataSource === "motherduck") return { type: 'duckdb' };

    return {
      type: 'duckdb'
    };
  }
};
