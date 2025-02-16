import { BooleanLike } from 'tgui-core/react';

/**
 * A map of keyed materials to a quantity.
 */
export type MaterialMap = Record<string, number>;

/**
 * A single, uniquely identifiable material.
 */
export type Material = {
  /**
   * The human-readable name of the material.
   */
  name: string;

  /**
   * An internal reference to the material that the server can use to uniquely
   * identify the material.
   */
  ref: string;

  /**
   * The amount of material; 100 units is one sheet.
   */
  amount: number;

  /**
   * The color of the material.
   */
  color: string;
};

/**
 * A single design that the fabricator can print.
 */
export type Design = {
  /**
   * The name of the design.
   */
  name: string;

  /**
   * A human-readable description of the design.
   */
  desc: string;

  /**
   * The individual material cost to print the design, adjusted for the
   * fabricator's part efficiency.
   */
  cost: MaterialMap;

  /**
   * A reference to the design's design datum.
   */
  id: string;

  /**
   * The categories the design should be present in. Subcategories are
   * slash-delimited, and categories always start with a slash.
   */
  categories: string[];

  /**
   * The icon used to represent this design, generated in
   * /datum/asset/spritesheet_batched/research_designs. **The image within may not be
   * 32x32.**
   */
  icon: string;
};

/**
 * The static and dynamic data made available to a fabricator UI.
 */
export type FabricatorData = {
  /**
   * The materials available to the fabricator, via ore silo or local storage.
   */
  materials: Material[];

  /**
   * Definition of how much units 1 sheet has.
   */
  SHEET_MATERIAL_AMOUNT: number;

  /**
   * The name of the fabricator, as displayed on the title bar.
   */
  fabName: string;

  /**
   * Whether mineral access is disabled from the ore silo (contact the
   * quartermaster).
   */
  onHold: BooleanLike;

  /**
   * The set of designs that this fabricator can print, indexed by their ID.
   */
  designs: Record<string, Design>;

  /**
   * Whether the fabricator is currently printing an item.
   */
  busy: BooleanLike;

  /**
   * The maximum quantity of material that the fabricator can hold, or `-1`
   * if the fabricator can hold infinitely many materials (such as the ore
   * silo).
   */
  materialMaximum: number;

  /**
   * The fabricator's current queue.
   */
  queue: {
    /**
     * The job ID for this queued job. This is always unique, and can be used
     * as a `key`.
     */
    jobId: number;

    /**
     * The design ID being printed. Available in `super.designs`.
     */
    designId: string;

    /**
     * If `true`, this design is currently being fabricated, and `timeLeft`
     * is actively decreasing.
     */
    processing: BooleanLike;

    /**
     * The time left in this design's fabrication, in deciseconds.
     */
    timeLeft: number;
  }[];
};
